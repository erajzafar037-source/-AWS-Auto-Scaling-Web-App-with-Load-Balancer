#!/bin/bash
set -euxo pipefail
%{ if !use_baked ~}
# Stock-AMI path: bootstrap the app at boot (slower; no Packer needed).
dnf install -y python3.11 python3.11-pip amazon-cloudwatch-agent
mkdir -p /opt/app && cd /opt/app
cat > main.py <<'PY'
import os, socket
from fastapi import FastAPI
app = FastAPI()
@app.get("/")
def root(): return {"version": os.getenv("APP_VERSION"), "host": socket.gethostname()}
@app.get("/health")
def health(): return {"status": "ok"}
PY
python3.11 -m pip install fastapi "uvicorn[standard]"
echo "APP_VERSION=${app_version}" > /etc/app.env
cat > /etc/systemd/system/web.service <<'UNIT'
[Unit]
After=network.target
[Service]
EnvironmentFile=/etc/app.env
WorkingDirectory=/opt/app
ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl enable --now web.service
%{ endif ~}

# CloudWatch agent: memory metric + system logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CW'
{
  "metrics": { "append_dimensions": { "AutoScalingGroupName": "$${aws:AutoScalingGroupName}" },
    "metrics_collected": { "mem": { "measurement": ["mem_used_percent"] } } },
  "logs": { "logs_collected": { "files": { "collect_list": [
    { "file_path": "/var/log/messages", "log_group_name": "/webapp/system", "log_stream_name": "{instance_id}" } ] } } }
}
CW
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
