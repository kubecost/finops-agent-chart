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
# volume, not in the agent container itself.
#
# Requires a cluster in the current kubectl context. Reruns are safe. Run locally against kind:
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
# Everything the run creates lives in the namespace -- secrets, the probe target, and the Helm
# release record -- so deleting it is the whole cleanup. Run before the test so reruns work,
# and again once it passes. Deliberately not on failure: diagnostics need the wreckage.
cleanup() { kubectl delete ns "$NS" --ignore-not-found --wait --timeout=180s >/dev/null; }

cleanup

# --- Certificates ---------------------------------------------------------------------------

openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj "/CN=finops-ci-test-ca" -keyout "$WORK/ca.key" -out "$WORK/ca.crt"
openssl req -newkey rsa:2048 -nodes -subj "/CN=ca-probe-target" -keyout "$WORK/tls.key" -out "$WORK/tls.csr"
openssl x509 -req -in "$WORK/tls.csr" -CA "$WORK/ca.crt" -CAkey "$WORK/ca.key" -CAcreateserial -days 1 -extfile <(echo "subjectAltName=DNS:$HOST") -out "$WORK/tls.crt"

# A unique base64 line from the CA PEM. Lets the checks below spot our CA inside a bundle
# without needing openssl in a container that does not have it.
MARKER=$(sed -n 3p "$WORK/ca.crt")

# --- Install --------------------------------------------------------------------------------

kubectl create ns "$NS"

# On a seconds-old cluster the SA controller has not populated "default" yet, and admission
# rejects pods until it does. The chart's deployment is retried; the bare probe pod is not.
kubectl -n "$NS" wait --for=create serviceaccount/default --timeout=120s

kubectl -n "$NS" create secret generic ca-certs-secret --from-file=ci-test-ca.crt="$WORK/ca.crt"
kubectl -n "$NS" create secret tls ca-probe-target-tls --cert="$WORK/tls.crt" --key="$WORK/tls.key"
kubectl -n "$NS" apply -f "$FIXTURE"

helm install "$RELEASE" "$CHART" -n "$NS" --wait --timeout 300s -f "$VALUES"
POD=$(kubectl -n "$NS" get pod -l app.kubernetes.io/name=finops-agent --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
[ -n "$POD" ] || fail "no running finops-agent pod"

# --- A: the agent resolves a bundle containing our CA ----------------------------------------

agent cat /etc/ssl/certs/ca-certificates.crt > "$WORK/builtin.pem" || fail "A: agent image has no built-in CA bundle; the guard below would be meaningless"
if grep -qF "$MARKER" "$WORK/builtin.pem"; then
  fail "A: test CA is already in the image's built-in bundle; this check proves nothing"
fi

# Go reads SSL_CERT_FILE first and stops there when it is readable, so this is exactly the
# bundle the agent will use. Unset or unreadable fails the script.
# shellcheck disable=SC2016  # single quotes are deliberate: expand inside the container
agent bash -c 'cat "${SSL_CERT_FILE:?not set on the agent container}"' > "$WORK/resolved.pem"
grep -qF "$MARKER" "$WORK/resolved.pem" || fail "A: custom CA absent from the bundle the agent will read"

echo "PASS A: agent resolves a bundle holding our CA, which is not baked into the image"

# --- B: a real handshake against the CA-signed server succeeds --------------------------------

kubectl -n "$NS" wait --for=condition=Ready pod/ca-probe-target --timeout=120s
# Read the bundle path off the live agent container rather than hardcoding it, so the probe
# cannot drift onto a stale path if the chart ever moves the bundle. 
CERT=$(agent printenv SSL_CERT_FILE)
RESPONSE=$(kubectl -n "$NS" exec "$POD" -c ca-probe -- env SSL_CERT_FILE="$CERT" curl -sS --fail --max-time 15 "https://$HOST/")
[ "$RESPONSE" = "finops-ca-probe-ok" ] || fail "B: unexpected response from probe target: $RESPONSE"

echo "PASS B: HTTPS handshake against the CA-signed server succeeded using that bundle"

# --- C: negative control, the handshake fails without our CA ----------------------------------

# Same server, from a throwaway pod holding only stock public roots, which cannot have signed a
# CA generated moments ago.
RC=0
kubectl -n "$NS" run ca-negative-control --rm --attach --quiet --restart=Never \
  --image=nginx:1-alpine --image-pull-policy=IfNotPresent \
  --command -- curl -sS --fail --max-time 15 "https://$HOST/" || RC=$?
# 60 is CURLE_PEER_FAILED_VERIFICATION. Assert that exact code rather than "any failure"
[ "$RC" -eq 60 ] || fail "C: expected curl 60 (certificate verification failed), got $RC"

echo "PASS C: the same handshake fails from a pod without our CA"

cleanup
echo "All CA-trust checks passed."
