#!/usr/bin/env bash
# CI smoke test: create secrets, install the chart (no --wait: the migrate hook gates web), wait for web, hit /health_check.
set -euo pipefail
NS=canvas
kubectl create ns "$NS"
kubectl -n "$NS" create secret generic canvas-secrets \
  --from-literal=ENCRYPTION_KEY="$(openssl rand -hex 24)" \
  --from-literal=DB_PASSWORD="$(openssl rand -hex 16)" \
  --from-literal=REDIS_PASSWORD="$(openssl rand -hex 16)" \
  --from-literal=CANVAS_LMS_ADMIN_PASSWORD="ci-$(openssl rand -hex 6)"
helm install canvas ./charts/canvas-lms -n "$NS" -f charts/canvas-lms/ci/kind-values.yaml --timeout 30m
kubectl -n "$NS" wait --for=condition=complete job/canvas-migrate-1 --timeout=30m || {
  kubectl -n "$NS" logs job/canvas-migrate-1 --tail=100; exit 1; }
kubectl -n "$NS" rollout status deploy -l app.kubernetes.io/component=web --timeout=15m
kubectl -n "$NS" run curl --rm -i --restart=Never --image=curlimages/curl -- \
  curl -fsS "http://$(kubectl -n "$NS" get svc -l app.kubernetes.io/component=web -o jsonpath='{.items[0].metadata.name}')/health_check"
