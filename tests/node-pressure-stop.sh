#!/bin/bash
# Undo tests/node-pressure-start.sh: restore the original kubelet config and restart the kubelet.
set -e
NODE=dsys601-lab-worker2
CONFIG=/var/lib/kubelet/config.yaml

docker exec "$NODE" mv "$CONFIG.task9.bak" "$CONFIG"
docker exec "$NODE" systemctl restart kubelet
echo "Original kubelet config restored on $NODE and kubelet restarted."
