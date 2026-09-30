# Teardown and reset procedure (Task 13)

Use this between cohorts, or any time the lab is broken, to return it to a clean, known-good state.

## What a reset removes and keeps

| Removed | Kept |
|---|---|
| The Kind cluster and its 3 node containers | This repo and its scripts |
| Node storage (Prometheus data, pod data) | `.env` (Grafana password) |
| Anything students created in the cluster | Downloaded images (makes rebuilds faster) |
| The `kind-dsys601-lab` kubectl context | The `kind` Docker network (Kind reuses it) |

## Before you start

1. Check with the teaching team that nobody still needs the current lab. All student work in the cluster will be lost.
2. Update the repo: `git pull`
3. Check `.env` exists. If not: `cp .env.example .env` and set `GRAFANA_ADMIN_PASSWORD`.

## Reset

```bash
./reset-lab.sh
```

Type `RESET` when asked. Takes about 2 minutes. It tears down, rebuilds from the repo, and runs `verify-lab.sh`.

## After the reset

1. The last lines must say `LAB READY: all checks passed`.
2. If any check says `FAIL`, run `./verify-lab.sh` again after a minute (pods can be slow to start). If it still fails, run `./reset-lab.sh` again.
3. Record the reset in the table below.

## Other commands

| Command | What it does |
|---|---|
| `./cluster/teardown-cluster.sh` | Delete the lab only (asks to confirm; checks nothing is left) |
| `./verify-lab.sh` | Health check only (11 PASS/FAIL checks) |

## Reset record

| Date | By | Repo version | Result |
|---|---|---|---|
| 30 Sep 2026 | Kabir Singh Thukrai | v1.0-lab-baseline-1-g66d3166 | LAB READY, 1 min 47 s |
