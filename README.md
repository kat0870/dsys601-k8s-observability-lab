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
```
