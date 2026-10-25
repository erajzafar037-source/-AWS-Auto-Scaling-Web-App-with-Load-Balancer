#!/usr/bin/env bash
# Creates a new GitHub repo under your account and pushes this project.
# Requires: git + GitHub CLI (https://cli.github.com), logged in via `gh auth login`.
set -euo pipefail
REPO="${1:-aws-autoscaling-webapp}"
VIS="${2:---public}"     # or --private
[ -d .git ] || { git init -b main; git add -A; git commit -m "Initial commit: AWS auto-scaling web app (Terraform, ALB, ASG, CI/CD)"; }
gh repo create "$REPO" "$VIS" --source=. --remote=origin --push
echo "Done: $(gh repo view --json url -q .url)"
