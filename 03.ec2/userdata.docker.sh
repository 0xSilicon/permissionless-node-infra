#!/bin/bash
set -eux

# Redirect all output (stdout and stderr) to both log file and system logger
exec > >(tee /var/log/userdata.log | logger -t userdata -s) 2>&1

# Prevent interactive prompts during package installation
export DEBIAN_FRONTEND=noninteractive

# Update system packages
apt update -y
apt dist-upgrade -y
apt upgrade -y

# Set up Docker repository
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin jq net-tools

apt autoremove -y

systemctl enable docker
systemctl start docker

# Wait for ssm-user to be created (max 2 minutes)
for i in {1..60}; do
  id -u ssm-user && break
  sleep 2
done

sudo docker network create silicon || true

echo "[✔] user_data.docker.sh completed successfully"
