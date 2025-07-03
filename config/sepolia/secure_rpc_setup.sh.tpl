#!/bin/bash

# Clone the repo
sudo git clone --branch feat/execs --single-branch https://github.com/radiusxyz/dockerized-sbb.git
mv dockerized-sbb /home/ubuntu/dockerized-sbb

# Write the .env file
cat <<EOF > /home/ubuntu/dockerized-sbb/.env
ROLLUP_ID="radius_rollup"
ROLLUP_RPC_URL="http://silicon-node:8123"
SECURE_RPC_PROVIDER_MODE="init"
SECURE_RPC_EXTERNAL_RPC_URL="http://0.0.0.0:8545"
TX_ORDERER_EXTERNAL_RPC_URL_LIST="http://35.189.33.95:11102"
DISTRIBUTED_KEY_GENERATOR_EXTERNAL_RPC_URL="http://35.189.33.95:11002"
ENCRYPTED_TRANSACTION_TYPE="skde"
EOF

# Write docker-compose file
echo "${secure_rpc_compose}" > /home/ubuntu/dockerized-sbb/docker-compose.yml

# Set permissions and run
chown -R ubuntu:ubuntu /home/ubuntu/dockerized-sbb/
sudo docker compose -f /home/ubuntu/dockerized-sbb/docker-compose.yml up -d