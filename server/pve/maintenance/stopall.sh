#!/bin/bash

# Target running VMs and containers only
mapfile -t listvm < <(qm list 2>/dev/null | awk 'NR>1 && $3=="running" {print $1}')
mapfile -t listct < <(pct list 2>/dev/null | awk 'NR>1 && $2=="running" {print $1}')

if [ "${#listvm[@]}" -eq 0 ] && [ "${#listct[@]}" -eq 0 ]; then
  echo "No running VMs or containers found. Server can be safely shutdown."
  exit 0
fi

if [ "${#listvm[@]}" -gt 0 ]; then
  echo "Initiating shutdown for running VMs: ${listvm[*]}"
  for vm in "${listvm[@]}"; do
    echo "Sending shutdown signal to VM $vm..."
    qm shutdown "$vm" || true
  done

  echo "Waiting for VMs to terminate..."
  for vm in "${listvm[@]}"; do
    qm wait "$vm" 60 2>/dev/null || echo "VM $vm wait timed out (may still be syncing disk caches)"
  done
fi

if [ "${#listct[@]}" -gt 0 ]; then
  echo "Initiating shutdown for running containers: ${listct[*]}"
  for ct in "${listct[@]}"; do
    echo "Sending shutdown signal to CT $ct..."
    pct shutdown "$ct" || true
  done

  echo "Waiting for containers to terminate..."
  for ct in "${listct[@]}"; do
    pct wait "$ct" 60 2>/dev/null || echo "CT $ct wait timed out"
  done
fi

echo "All guests processed. PVE Server can now be safely shutdown."

