#!/bin/bash
# Task 9 failure-injection test: make one Kind worker report DiskPressure without
# filling the disk. Adds a SOFT eviction threshold (nodefs.available < 30%) with a
# 1 hour grace period, so the kubelet reports DiskPressure but does not evict pods
# during the test. Expected alert: DSYS601NodeUnderPressure.
# Undo with tests/node-pressure-stop.sh well before the hour is up.
set -e
NODE=dsys601-lab-worker2
CONFIG=/var/lib/kubelet/config.yaml

if docker exec "$NODE" test -f "$CONFIG.task9.bak"; then
  echo "Test already running on $NODE. Run tests/node-pressure-stop.sh first."
  exit 1
fi

docker exec "$NODE" cp "$CONFIG" "$CONFIG.task9.bak"
docker exec -i "$NODE" sh -c "cat >> $CONFIG" <<'EOF'
evictionSoft:
  nodefs.available: "30%"
evictionSoftGracePeriod:
  nodefs.available: "1h"
EOF
docker exec "$NODE" systemctl restart kubelet
echo "Soft disk threshold added on $NODE and kubelet restarted."
