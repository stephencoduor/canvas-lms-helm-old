# canvas-lms chart (v1, alpha)

A production-oriented refactor of the chart in `../../chart` (0.10.0). The original chart and the Tilt dev loop are untouched. This chart lives alongside it until it reaches parity.

## What changed from 0.10.0

| Area | 0.10.0 (`chart/`) | v1 (`charts/canvas-lms/`) |
|---|---|---|
| Secrets | Defaults in `values.yaml` (`sample-encryption-key`, `password`) | No secret values. `canvas.existingSecret` is `required`; render fails without it |
| LTI 1.3 | Stock keys | Your own past/present/future JWKs from `canvas.ltiKeysSecret`; `lti_iss` from your domain |
| Web and jobs | Two containers in one pod | Separate Deployments, resources, grace periods and PDBs |
| Migrations | Init container on every replica | One Job per release: `post-install,pre-upgrade` hook, `backoffLimit: 1`, deadline |
| Probes | `/` with a 60s delay | startup/readiness/liveness on `/health_check`, `preStop` drain |
| Rollouts | Default | `maxUnavailable: 0`, config checksum annotation |
| Availability | none | PDBs, topology spread |
| Network | none | NetworkPolicy: Postgres/Redis accept only Canvas pods (`networkPolicy.allowFromNamespaces` for extras) |
| Pod security | root `busybox` chown | uid 9999, `fsGroup`; jobs/migrate fully restricted. Web keeps privilege escalation because Passenger starts nginx via sudo |
| Scaling | HPA on the shared pod | HPA for web; KEDA `ScaledObject` for jobs on the `delayed_jobs` backlog |
| Monitoring | none | PrometheusRule for a failed migration job; ServiceMonitor toggle |
| Images | `appVersion: latest` | `appVersion` is a Canvas release; optional `image.digest` |

## Not yet ported (needed for parity)

- RCE API Deployment/Service (`deployment-rce.yaml`, `service-rce.yaml`)
- `brandable_css` PVC
- Bitnami Postgres/Redis subcharts (v1 has a small in-chart dev Postgres and Redis, or points at external ones)
- Tilt integration (the `Tiltfile` still targets `chart/`)

## Quick start

```bash
kubectl create ns canvas
kubectl -n canvas create secret generic canvas-secrets \
  --from-literal=ENCRYPTION_KEY="$(openssl rand -hex 24)" \
  --from-literal=DB_PASSWORD="$(openssl rand -hex 16)" \
  --from-literal=REDIS_PASSWORD="$(openssl rand -hex 16)" \
  --from-literal=CANVAS_LMS_ADMIN_PASSWORD="$(openssl rand -base64 18)"
helm install canvas ./charts/canvas-lms -n canvas --set canvas.domain=canvas.example.com
kubectl -n canvas logs -f job/canvas-migrate-1
```

Don't use `helm install --wait` on first install: the migration runs as a post-install hook and the web pods wait for the schema.
