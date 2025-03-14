apt update -y
apt dist-upgrade -y
add-apt-repository ppa:ethereum/ethereum -y
apt update -y
apt upgrade -y
apt install ethereum -y
apt autoremove -y

while true; do
  id -u ssm-user
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 1s
done

mkdir -p /home/ssm-user/beacon
curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output /home/ssm-user/beacon/prysm.sh && chmod +x /home/ssm-user/beacon/prysm.sh
touch /home/ssm-user/beacon/tosaccepted
wget https://github.com/jaybbbb/snippet/raw/master/metaData -O /home/ssm-user/beacon/metaData
chown -R ssm-user:ssm-user /home/ssm-user/beacon

/home/ssm-user/beacon/prysm.sh beacon-chain generate-auth-secret --output-file /home/ssm-user/jwt.hex
chmod a+r /home/ssm-user/jwt.hex

mkdir -p /home/ssm-user/execution
chown -R ssm-user:ssm-user /home/ssm-user/execution