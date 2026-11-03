#!/usr/bin/env bash
# Usage: ./scripts/load_test.sh https://<alb-dns> [requests] [concurrency]
# -k because the lab cert is self-signed. Hits /cpu to push ASG CPU over the target.
set -euo pipefail
URL="${1:?alb url}"; N="${2:-20000}"; C="${3:-100}"
ab -k -n "$N" -c "$C" "$URL/cpu?n=3000000"
