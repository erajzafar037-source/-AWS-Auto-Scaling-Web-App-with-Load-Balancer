#!/usr/bin/env bash
# Block until the latest ASG instance refresh succeeds (fails the pipeline otherwise).
set -euo pipefail
ASG="$1"
for i in $(seq 1 90); do
  STATUS=$(aws autoscaling describe-instance-refreshes --auto-scaling-group-name "$ASG" \
            --max-records 1 --query 'InstanceRefreshes[0].Status' --output text)
  echo "[$i] instance refresh: $STATUS"
  case "$STATUS" in
    Successful|None) exit 0 ;;
    Failed|Cancelled|RollbackSuccessful) exit 1 ;;
  esac
  sleep 20
done
echo "timeout"; exit 1
