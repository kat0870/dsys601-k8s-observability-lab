# DSYS601 lab handover guide (Task 14)

This repo builds the DSYS601 Kubernetes observability lab: a 3-node Kind cluster, a small
demo app, and Prometheus, Grafana and Alertmanager with the DSYS601 dashboard and alerts.

## Host requirements

| Item | Minimum | Tested on |
|---|---|---|
| OS | Ubuntu 22.04 LTS, amd64 | Ubuntu 22.04.5 |
| CPU | 4 cores | 4 cores |
| Memory | 8 GB | 10 GB (lab uses about 3 GB) |
| Disk | 40 GB | 20 GB (too small: only 3 GB left free) |
| Internet | Needed for setup and resets (downloads several GB) | |

## Set up from a blank machine

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/kat0870/dsys601-k8s-observability-lab.git
cd dsys601-k8s-observability-lab
./install-tools.sh            # then reboot (for the docker group and cgroup settings)
cp .env.example .env          # then edit .env and set GRAFANA_ADMIN_PASSWORD
./reset-lab.sh                # type RESET; must end with LAB READY
```

## Opening the tools

| Tool | Command | Then open |
|---|---|---|
| Grafana | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | http://localhost:3000 (user `admin`, password from `.env`) |
| Prometheus | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090` | http://localhost:9090 |
| Alertmanager | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093` | http://localhost:9093 |

The DSYS601 dashboard is called **DSYS601 Workload Health**.

## Everyday commands

| Command | What it does |
|---|---|
| `./verify-lab.sh` | Health check (11 PASS/FAIL checks) |
| `./reset-lab.sh` | Wipe and rebuild the lab (see docs/teardown-reset.md) |
| `./cluster/teardown-cluster.sh` | Delete the lab only |
| `kubectl apply -f tests/crashloop-test.yaml` | Failure test: the crashloop alert fires after about 7 minutes |

## If something goes wrong

| Problem | Fix |
|---|---|
| `LAB NOT READY` | Wait a minute and run `./verify-lab.sh` again. If it still fails, run `./reset-lab.sh`. |
| `permission denied` using docker | Log out and back in after `install-tools.sh`. |
| Disk full / pods stuck | Check with `docker system df` and `df -h /`. The host needs 40 GB. |
| Port-forward says address in use | Another port-forward is already running; close that terminal. |

## Known issues

- Some built-in alerts (`TargetDown`, `KubeProxyInstanceUnreachable` and similar) fire on a
  healthy cluster, because Kind only exposes some metrics inside its nodes. The DSYS601 alerts
  are not affected.

## Other documents

- `docs/reproducibility.md`: what is pinned and how to upgrade versions
- `docs/teardown-reset.md`: the reset checklist and reset record
- `versions.env`: the exact tool and chart versions
