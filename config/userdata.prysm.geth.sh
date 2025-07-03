apt update -y
apt dist-upgrade -y
add-apt-repository ppa:ethereum/ethereum -y
apt update -y
apt upgrade -y
apt install ethereum -y
apt autoremove -y

mkdir -p /home/ubuntu/beacon
curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output /home/ubuntu/beacon/prysm.sh && chmod +x /home/ubuntu/beacon/prysm.sh
touch /home/ubuntu/beacon/tosaccepted
wget https://github.com/jaybbbb/snippet/raw/master/metaData -O /home/ubuntu/beacon/metaData
chown -R ubuntu:ubuntu /home/ubuntu/beacon

/home/ubuntu/beacon/prysm.sh beacon-chain generate-auth-secret --output-file /home/ubuntu/jwt.hex
chmod a+r /home/ubuntu/jwt.hex

mkdir -p /home/ubuntu/execution
chown -R ubuntu:ubuntu /home/ubuntu/execution