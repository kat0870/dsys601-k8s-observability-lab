# Reproducibility and version pinning (Task 12)

The whole lab (cluster, demo app, monitoring stack, dashboards and alert rules) is rebuilt
from this repository. Nothing is installed "latest"; every version is pinned.

## What is pinned, and where

| Layer | Pinned to | Where |
|---|---|---|
| Tool versions (kind, kubectl, helm, docker) | exact versions, checked by setup script | `versions.env` |
| Kind node image | tag + sha256 digest | `versions.env`, `cluster/kind-config.yaml` |
| kube-prometheus-stack Helm chart | exact chart version | `versions.env` (read by `monitoring/setup-monitoring.sh`) |
| Demo app and test images | tag + sha256 digest | `app/`, `tests/`, `task11/` |
| Dashboards | JSON in git, loaded via ConfigMap | `monitoring/dashboards/` |
| Alert rules | PrometheusRule YAML in git | `monitoring/alerts/` |

`cluster/setup-cluster.sh` warns if installed tools differ from `versions.env` and stops if
`kind-config.yaml` does not use the node image pinned in `versions.env`.

## Secrets

The Grafana admin password is the only thing not stored in git. It is read from `.env`
(ignored by git). Copy `.env.example` to `.env` and set a password before installing.

## Rebuild from scratch

```bash
git clone https://github.com/kat0870/dsys601-k8s-observability-lab.git
cd dsys601-k8s-observability-lab
cp .env.example .env              # then edit .env and set GRAFANA_ADMIN_PASSWORD
./cluster/setup-cluster.sh
kubectl apply -f app/demo-app.yaml
./monitoring/setup-monitoring.sh
```

## Upgrading a version (between cohorts)

1. Change the version in `versions.env` (and digests in manifests if images change).
2. Tear down and rebuild from a fresh clone.
3. Verify: nodes Ready, all pods Running, and a failure test fires its alert.
4. Commit, push, and tag the verified state.

## Verification record

On 30 September 2026 the lab was rebuilt from a fresh clone of GitHub. Cluster, demo app and
monitoring stack all came up healthy, the Grafana password was confirmed to come from `.env`,
and the crashloop failure test fired `DSYS601PodCrashLooping` as designed. The first rebuild
attempt failed on an empty `grafana:` key in `values.yaml`; this was fixed in commit `2d7a3ee`.

## Known gaps and recommendations

- **Kind moved to a stable release** (v0.33.0, 30 Sep 2026). It uses the same pinned node
  image digest, and a full reset passed all checks. The old alpha build is kept as
  `/usr/local/bin/kind-alpha-backup` on the original VM.
- **Image digests were captured on 30 Sep 2026.** Floating tags (`redis:7.4-alpine`,
  `nginx:1.27-alpine`) may have resolved to newer patch builds than those used in Tasks 5-9.
  The rebuild test verified the pinned builds work.
- **A Grafana password was committed earlier** (commit `b2842ef`). It was rotated and moved to
  `.env`; the old value no longer works.
- **Kind scrape-target noise:** control-plane and kube-proxy metrics are only exposed on
  127.0.0.1 inside Kind nodes, so built-in `TargetDown` / `*InstanceUnreachable` alerts fire
  on a healthy cluster. Follow-up: expose these metrics in `kind-config.yaml` or disable those
  targets in `values.yaml`.
