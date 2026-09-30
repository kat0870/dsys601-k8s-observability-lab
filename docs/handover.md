# DSYS601 lab handover guide (Task 14)

This repo builds the DSYS601 Kubernetes observability lab: a 3-node Kind cluster, a small
demo app, and Prometheus, Grafana and Alertmanager with the DSYS601 dashboard and alerts.

## Host requirements

| Item | Minimum | Dev VM | Fresh college VM (30 Sep 2026) |
|---|---|---|---|
| OS | Ubuntu 22.04 LTS, amd64 | Ubuntu 22.04.5 | Ubuntu 22.04.1 (college base image) |
| CPU | 4 cores | 4 cores | 4 cores |
| Memory | 8 GB | 10 GB | 8 GB (lab uses about 3 GB) |
| Disk | 40 GB | 20 GB (too small: only 3 GB left free) | 20 GB system + 40 GB for `/var/lib/docker` |
| Internet | Needed for setup and resets (downloads several GB) | | |

The lab uses about 7 GB of disk: about 2.3 GB for Docker and the tools, and about 4.6 GB for the Kind nodes and images.

## College VMs (linked clones)

The college Ubuntu VMs in `P:\Clones` are linked clones with a fixed 20 GB disk.
VMware cannot expand this disk, so add a second disk for Docker instead.

1. Copy `P:\Clones\Ubuntu 224 LTS` to its own folder on D: and open the `.vmx` in VMware.
2. With the VM off, set Memory to 8 GB and Processors to 4.
3. Add a new hard disk: Settings > Add > Hard Disk > SCSI > 40 GB, single file.
4. Power on and choose "I Copied It".
5. Before running anything else, check the new disk is `sdb` (40G, no partitions) with `lsblk`, then:

```bash
sudo mkfs.ext4 -L docker-data /dev/sdb
sudo mkdir -p /var/lib/docker
echo 'LABEL=docker-data /var/lib/docker ext4 defaults 0 2' | sudo tee -a /etc/fstab
sudo mount -a
df -h /var/lib/docker    # should show about 40G
```

Then carry on with the steps below.

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
| `kubectl apply -f tests/crashloop-test.yaml` | Failure test: the crashloop alert fires after about 7–9 minutes. Remove it with `kubectl delete -f tests/crashloop-test.yaml`; the alert clears about 5 minutes later |

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
