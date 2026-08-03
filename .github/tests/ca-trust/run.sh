#!/usr/bin/env bash
#
# End-to-end verification of the chart's global.updateCaTrust feature.
#
# Generates a throwaway CA, serves HTTPS with a certificate signed by it, installs the chart
# with the feature enabled, and checks that the agent pod ends up actually trusting that CA:
#
#   A  the agent container resolves a CA bundle containing our CA -- and that CA is not already
#      baked into the image, which would make A pass regardless of what the init container did
#   B  a real HTTPS handshake against the CA-signed server succeeds
#   C  negative control: the same handshake fails when the custom CA is not supplied
#
# Known limitation: the agent image (ubi9-micro) ships only coreutils and bash -- no curl, no
# openssl -- so the handshakes in B and C run in a sidecar that shares the agent's bundle
# volume, not in the agent container itself. If the agent binary overrides RootCAs in its own
# code, every check here passes and the feature is still broken. Closing that gap needs an
# agent-side change, not a chart change.
#
# Requires a cluster in the current kubectl context. Run locally against kind with:
#   kind create cluster && .github/tests/ca-trust/run.sh

set -euo pipefail

NS=${NS:-finops-ca-test}
RELEASE=${RELEASE:-finops-ca-test}
CHART=${CHART:-./charts/finops-agent}
VALUES=${VALUES:-.github/tests/ca-trust/values.yaml}
FIXTURE=${FIXTURE:-.github/tests/ca-trust/probe-target.yaml}

HOST="ca-probe-target.${NS}.svc.cluster.local"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
agent() { kubectl -n "$NS" exec "$POD" -c finops-agent -- "$@"; }
probe() { kubectl -n "$NS" exec "$POD" -c ca-probe -- "$@"; }
probe_image() {
  kubectl -n "$NS" get pod "$POD" \
    -o jsonpath='{.spec.containers[?(@.name=="ca-probe")].image}'
}

generate_certs() {
  openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
    -subj "/CN=finops-ci-test-ca" -keyout "$WORK/ca.key" -out "$WORK/ca.crt"
  openssl req -newkey rsa:2048 -nodes -subj "/CN=ca-probe-target" \
    -keyout "$WORK/tls.key" -out "$WORK/tls.csr"
  # The SAN must match the in-cluster DNS name, or the handshake fails for an unrelated
  # reason and the failure is misleading.
  openssl x509 -req -in "$WORK/tls.csr" -CA "$WORK/ca.crt" -CAkey "$WORK/ca.key" \
    -CAcreateserial -days 1 -extfile <(echo "subjectAltName=DNS:$HOST") -out "$WORK/tls.crt"
  # A unique base64 line from the CA PEM. Lets the checks below spot our CA inside a bundle
  # without needing openssl in a container that does not have it.
  MARKER=$(sed -n 3p "$WORK/ca.crt")
}

create_secrets_and_fixture() {
  kubectl create ns "$NS"
  # The chart references this secret by name but never creates it, so it must exist before
  # install or the pod blocks in ContainerCreating.
  kubectl -n "$NS" create secret generic ca-certs-secret --from-file=ci-test-ca.crt="$WORK/ca.crt"
  kubectl -n "$NS" create secret tls ca-probe-target-tls \
    --cert="$WORK/tls.crt" --key="$WORK/tls.key"
  # Applied before the chart install so the nginx pull overlaps the agent's; nothing waits on
  # it until check B.
  kubectl -n "$NS" apply -f "$FIXTURE"
}

install_chart() {
  helm install "$RELEASE" "$CHART" -n "$NS" --wait --timeout 300s -f "$VALUES"
  POD=$(kubectl -n "$NS" get pod -l app.kubernetes.io/name=finops-agent \
    --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
  [ -n "$POD" ] || fail "no running finops-agent pod"
}

check_a_agent_resolves_our_ca() {
  agent cat /etc/ssl/certs/ca-certificates.crt > "$WORK/builtin.pem" \
    || fail "agent image has no built-in CA bundle; the guard below would be meaningless"
  if grep -qF "$MARKER" "$WORK/builtin.pem"; then
    fail "test CA is already in the image's built-in bundle; this check proves nothing"
  fi

  # Go reads SSL_CERT_FILE first and stops there when it is readable, so this is exactly the
  # bundle the agent will use. Unset or unreadable fails the script.
  # shellcheck disable=SC2016  # single quotes are deliberate: expand inside the container
  agent bash -c 'cat "${SSL_CERT_FILE:?not set on the agent container}"' > "$WORK/resolved.pem"
  grep -qF "$MARKER" "$WORK/resolved.pem" \
    || fail "custom CA absent from the bundle the agent will read"
}

check_b_handshake_succeeds() {
  kubectl -n "$NS" wait --for=condition=Ready "pod/ca-probe-target" --timeout=120s
  # Read the path off the live agent container rather than hardcoding it, so the probe cannot
  # drift onto a stale path if the chart ever moves the bundle.
  local cert out
  cert=$(agent printenv SSL_CERT_FILE)
  # Deliberately no --cacert and no -k: trust must come from SSL_CERT_FILE alone.
  out=$(probe env SSL_CERT_FILE="$cert" curl -sS --fail --max-time 15 "https://$HOST/")
  [ "$out" = "finops-ca-probe-ok" ] || fail "unexpected response from probe target: $out"
}

check_c_handshake_fails_without_our_ca() {
  # Same image, server, and network path as B, but in a throwaway pod that does not mount the
  # extracted bundle -- so it has only stock public roots, which cannot have signed a CA
  # generated moments ago. If this succeeds, check B was never proving anything.
  #
  # It has to be a separate pod: ubi9-minimal symlinks /etc/ssl/certs into
  # /etc/pki/ca-trust/extracted, which is exactly where the sidecar mounts the shared bundle.
  # Any curl inside the sidecar therefore finds our CA even with SSL_CERT_FILE unset.
  if kubectl -n "$NS" run ca-negative-control --rm --attach --quiet --restart=Never \
      --image="$(probe_image)" -- curl -sS --fail --max-time 15 "https://$HOST/"; then
    fail "handshake succeeded without the custom CA; check B proves nothing"
  fi
}

generate_certs
create_secrets_and_fixture
install_chart
check_a_agent_resolves_our_ca
check_b_handshake_succeeds
check_c_handshake_fails_without_our_ca
echo "All CA-trust checks passed."
