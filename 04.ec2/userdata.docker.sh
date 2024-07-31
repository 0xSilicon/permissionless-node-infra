apt update -y
apt dist-upgrade -y
apt upgrade -y

#Set up Docker's apt repository.
## Add Docker's official GPG key:
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y

#Install the Docker packages
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin jq net-tools-y
apt autoremove -y

while true; do
  id -u ssm-user
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 1s
done