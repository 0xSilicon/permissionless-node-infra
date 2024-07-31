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

wget https://gist.githubusercontent.com/jaybbbb/2d91db691b754378e934e57453e9aa69/raw/prysm.service -O /lib/systemd/system/prysm.service
systemctl enable prysm.service; systemctl restart prysm.service

mkdir -p /home/ssm-user/execution
chown -R ssm-user:ssm-user /home/ssm-user/execution

wget https://gist.githubusercontent.com/jaybbbb/2d91db691b754378e934e57453e9aa69/raw/geth.service -O /lib/systemd/system/geth.service
systemctl enable geth.service; systemctl restart geth.service