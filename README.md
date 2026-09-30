# DSYS601 Kubernetes Observability Lab

A reproducible, multi-node Kubernetes lab environment (1 control-plane, 2 worker nodes)
built with Kind, used to develop observability labs for DSYS601.

## Prerequisites

- Docker (tested on Docker 29.8.1)
- Kind (tested on v0.34.0-alpha)
- kubectl (tested on v1.37.0)
- Ubuntu 22.04 LTS (or similar Linux host/VM)

## Known issue: cgroup delegation (read this first)

On some Ubuntu VMs (including the lab machines used for this project), the default
systemd configuration does not delegate all required cgroup controllers to user
sessions. This causes `kind create cluster` to fail while joining worker nodes, with
kubelet reporting "cgroups misconfigured" or a healthz timeout.

**Symptom check:**
```bash
cat /sys/fs/cgroup/user.slice/cgroup.subtree_control
```
If this does **not** show `cpu`, `cpuset`, `io`, `memory` and `pids` all together, apply the fix below.

**Fix:**
```bash
sudo mkdir -p /etc/systemd/system/user@.service.d
sudo tee /etc/systemd/system/user@.service.d/delegate.conf <<'EOF'
[Service]
Delegate=cpu cpuset io memory pids
EOF
sudo systemctl daemon-reload
sudo reboot
```

After rebooting, re-check the command above — it should now list all five controllers.

## Building the cluster

From the **repo root**:
```bash
./cluster/setup-cluster.sh
```

This creates a 3-node cluster (`dsys601-lab`) using the pinned `kindest/node:v1.37.0`
image, as defined in `cluster/kind-config.yaml`.

Verify:
```bash
kubectl get nodes
```

## Deploying the demo application

```bash
kubectl apply -f app/demo-app.yaml
kubectl get pods -n demo-app
```

This deploys a 3-tier demo app (frontend/nginx, API/go-httpbin, datastore/redis) used
as the observation target for the monitoring stack.

Test it:
```bash
kubectl port-forward -n demo-app svc/frontend 8081:80    # then curl localhost:8081
kubectl port-forward -n demo-app svc/api 8082:8080        # then curl localhost:8082/get
```

## Installing the monitoring stack

```bash
./monitoring/setup-monitoring.sh
kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=300s
```

This installs the kube-prometheus-stack Helm chart (pinned to version 91.5.3,
settings in `monitoring/values.yaml`) into the `monitoring` namespace, then loads:

- the Grafana dashboard "DSYS601 Workload Health" from `monitoring/dashboards/`
  (a ConfigMap labelled `grafana_dashboard=1`), and
- the alerting rules from `monitoring/alerts/` (a PrometheusRule labelled
  `release=kube-prometheus-stack`, which is the label Prometheus selects rules by).

The script uses `helm install`, so run it on a fresh cluster.

Access (run each command in its own terminal tab and leave it open):

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80        # http://localhost:3000
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090   # http://localhost:9090
```

The Grafana login is set in `monitoring/values.yaml`.

### Alerting rules

All rules are in `monitoring/alerts/dsys601-alerts.yaml` (rule group
`dsys601-workload.rules`). The workload rules only watch the `demo-app` namespace.

| Alert | Fires when | For | Severity |
|---|---|---|---|
| `DSYS601PodCrashLooping` | A container has been in CrashLoopBackOff at any point in the last 5 minutes | 5m | critical |
| `DSYS601ContainerMemoryNearLimit` | A container's working-set memory is above 90% of its memory limit | 10m | warning |
| `DSYS601PodNotReady` | A pod that should be running (Pending, Running or Unknown) is not Ready | 5m | warning |
| `DSYS601NodeUnderPressure` | A node's kubelet reports MemoryPressure, DiskPressure or PIDPressure | 10m | warning |

Design notes:

- The `for` times are long enough that normal startups, rollouts and short
  spikes do not fire an alert. On the healthy demo app all four rules are inactive.
- The node rule uses the kubelet's pressure conditions (via kube-state-metrics)
  instead of node-exporter. Kind nodes are Docker containers on one VM, so
  node-exporter reports the same host resources for every node. For the same
  reason, a real shortage on the VM makes all three nodes report pressure together.
- The kubelet keeps a pressure condition on for about 5 minutes after the pressure
  ends, so the node rule waits 10 minutes to ignore short spikes.
- The chart's built-in rules (for example `KubePodCrashLooping`, `KubePodNotReady`
  and `KubeNodePressure`) are still enabled. The `DSYS601` rules are scoped to this
  lab, with shorter, documented timings.

Check that the rules are loaded (rule changes take about a minute to appear):

```bash
curl -s http://localhost:9090/api/v1/rules | grep -o 'DSYS601[A-Za-z]*' | sort -u
```

This should list all four `DSYS601` alerts.

## Tearing down

```bash
./cluster/teardown-cluster.sh
```

## Repository structure

```
cluster/
  kind-config.yaml       # 3-node cluster definition (pinned image versions)
  setup-cluster.sh        # creates the cluster (run from repo root)
  teardown-cluster.sh     # deletes the cluster
app/
  demo-app.yaml           # frontend, API and datastore Deployments/Services
monitoring/
  setup-monitoring.sh      # installs kube-prometheus-stack 91.5.3, the dashboard and the alert rules
  values.yaml              # Helm chart settings
  dashboards/
    dsys601-workload-health.json   # Grafana dashboard, loaded via a labelled ConfigMap
  alerts/
    dsys601-alerts.yaml    # PrometheusRule with the four DSYS601 alerts
```

## Rebuilding the lab

See [docs/reproducibility.md](docs/reproducibility.md) for what is pinned, how to rebuild from scratch, and how to upgrade versions safely.
