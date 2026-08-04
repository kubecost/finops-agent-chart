#!/usr/bin/env bash
#
# End-to-end verification of the chart's global.updateCaTrust feature.
#
# Serves S3 over HTTPS with a certificate signed by a throwaway CA, points the agent's
# federated-storage client at it, and checks that the agent trusts that CA:
#
#   A  with the CA supplied, the agent completes the handshake and starts
#   B  negative control: without it, the agent rejects the same certificate
#
# The handshake is performed by the agent process itself, so unlike a sidecar-based probe this
# fails if the agent ignores the bundle the init container installs.
#
# Requires a cluster in the current kubectl context. Reruns are safe. Run locally against kind:
#   kind create cluster && .github/tests/ca-trust/run.sh

set -euo pipefail

NS=finops-ca-test  # must match the endpoint in values.yaml
RELEASE=${RELEASE:-finops-ca-test}
CHART=${CHART:-./charts/finops-agent}
VALUES=${VALUES:-.github/tests/ca-trust/values.yaml}
FIXTURE=${FIXTURE:-.github/tests/ca-trust/minio.yaml}

HOST="minio.${NS}.svc.cluster.local"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
agent_logs() { kubectl -n "$NS" logs -l app.kubernetes.io/name=finops-agent --tail=-1 2>/dev/null; }
# Everything the run creates lives in the namespace -- secrets, MinIO, and the Helm release
# record -- so deleting it is the whole cleanup. Run before the test so reruns work, and again
# once it passes. Deliberately not on failure: diagnostics need the wreckage.
cleanup() { kubectl delete ns "$NS" --ignore-not-found --wait --timeout=180s >/dev/null; }

cleanup

# --- Certificates ---------------------------------------------------------------------------

openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj "/CN=finops-ci-test-ca" -keyout "$WORK/ca.key" -out "$WORK/ca.crt"
openssl req -newkey rsa:2048 -nodes -subj "/CN=minio" -keyout "$WORK/tls.key" -out "$WORK/tls.csr"
openssl x509 -req -in "$WORK/tls.csr" -CA "$WORK/ca.crt" -CAkey "$WORK/ca.key" -CAcreateserial -days 1 -extfile <(echo "subjectAltName=DNS:$HOST") -out "$WORK/tls.crt"

# --- Install --------------------------------------------------------------------------------

kubectl create ns "$NS"

# On a seconds-old cluster the SA controller has not populated "default" yet, and admission
# rejects pods until it does. The chart's deployment is retried; the bare MinIO pod is not.
kubectl -n "$NS" wait --for=create serviceaccount/default --timeout=120s

kubectl -n "$NS" create secret generic ca-certs-secret --from-file=ci-test-ca.crt="$WORK/ca.crt"
kubectl -n "$NS" create secret tls minio-tls --cert="$WORK/tls.crt" --key="$WORK/tls.key"
kubectl -n "$NS" apply -f "$FIXTURE"
kubectl -n "$NS" wait --for=condition=Ready pod/minio --timeout=120s

# --- A: the agent trusts the CA and starts ---------------------------------------------------

helm install "$RELEASE" "$CHART" -n "$NS" --wait --timeout 300s -f "$VALUES"

# Logged only after the emitter's startup write/read/delete round-trip against the bucket has
# succeeded, so reaching it means a real TLS handshake completed inside the agent.
agent_logs | grep -q "Successfully created bucket storage" || fail "A: agent never reached the bucket"

# A failed handshake panics the agent rather than degrading it, so any restart means the run
# below would be testing a container that is already broken.
RESTARTS=$(kubectl -n "$NS" get pod -l app.kubernetes.io/name=finops-agent -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}')
[ "$RESTARTS" -eq 0 ] || fail "A: agent restarted $RESTARTS time(s) despite being given the CA"

echo "PASS A: the agent completed a TLS handshake against the CA-signed server"

# --- B: negative control, the agent rejects the same certificate ------------------------------

# Same server, same config, CA withheld. Without this an image that already trusted the CA --
# or one that skipped verification entirely -- would pass A.
helm upgrade "$RELEASE" "$CHART" -n "$NS" -f "$VALUES" --set global.updateCaTrust.enabled=false >/dev/null

# The crashing pod flaps to Ready between panics, so poll the logs rather than pod status.
for _ in $(seq 60); do
  if agent_logs | grep -q "x509: certificate signed by unknown authority"; then break; fi
  sleep 5
done
agent_logs | grep -q "x509: certificate signed by unknown authority" || fail "B: agent did not reject the untrusted certificate"

echo "PASS B: the agent rejected the same certificate when the CA was withheld"

cleanup
echo "All CA-trust checks passed."
