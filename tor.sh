#!/usr/bin/env bash
sudo apt-get update -y
sudo apt-get install tor -y
# 

sudo bash -c 'cat >> /etc/tor/torrc' << EOF
HiddenServiceDir /var/lib/tor/mainnet/
HiddenServiceVersion 3
HiddenServicePort 8080 127.0.0.1:8080
EOF

sudo /etc/init.d/tor restart
onion_v3=$(sudo cat /var/lib/tor/mainnet/hostname)
sudo sed -i "s!export ONION_V3=.*!export ONION_V3=\"http://$onion_v3:8080\"!" /mnt/disks/sdb/esplora/flavors/bitcoin-mainnet/config.env

cat >> /mnt/disks/sdb/esplora/flavors/bitcoin-mainnet/config.env << EOF
export HEAD_HTML="<meta http-equiv="onion-location" content="http://$onion_v3:8080" />"
EOF

cd /mnt/disks/sdb/esplora
sudo systemctl stop mainnet
sudo docker build -t esplora .
sudo npm run dist
sudo systemctl restart docker
sudo systemctl start mainnet
