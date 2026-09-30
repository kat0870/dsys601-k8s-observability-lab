#!/bin/bash
# Resets the DSYS601 lab between cohorts: tear down, rebuild from this repo, verify.
# Usage: ./reset-lab.sh (asks for confirmation) or ./reset-lab.sh --yes (no prompt)
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "== DSYS601 lab reset started: $(date '+%Y-%m-%d %H:%M:%S') =="
echo "Repo version: $(git describe --tags --always)"
if [ -n "$(git status --porcelain)" ]; then
  echo "WARNING: this folder has uncommitted changes, so the rebuild may not match GitHub."
fi
[ -f .env ] || { echo "ERROR: .env missing. Copy .env.example to .env and set GRAFANA_ADMIN_PASSWORD."; exit 1; }

if [ "${1:-}" != "--yes" ]; then
  echo "This will DELETE and REBUILD the whole lab. Anything students created in the cluster will be lost."
  read -r -p "Type RESET to continue: " answer
  [ "$answer" = "RESET" ] || { echo "Cancelled."; exit 1; }
fi

echo "== 1/5 Teardown =="
./cluster/teardown-cluster.sh --yes
echo "== 2/5 Build cluster =="
./cluster/setup-cluster.sh
echo "== 3/5 Deploy demo app =="
kubectl apply -f app/demo-app.yaml
echo "== 4/5 Install monitoring =="
./monitoring/setup-monitoring.sh
echo "== 5/5 Verify =="
./verify-lab.sh
echo "== Reset finished in $((SECONDS / 60)) min $((SECONDS % 60)) s =="
