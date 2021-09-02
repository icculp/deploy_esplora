#!/usr/bin/env bash

# mount volume in Linode - if you used a different name, change esplora to the name you used
# this might look different in other cloud providers

# sudo mkfs.ext4 "/dev/disk/by-id/scsi-0Linode_Volume_esplora_volume"
# sudo mkdir "/mnt/esplora_volume"
# sudo mount "/dev/disk/by-id/scsi-0Linode_Volume_esplora_volume" "/mnt/esplora_volume"

# ensure mount on boot
# echo "/dev/disk/by-id/scsi-0Linode_Volume_esplora_volume /mnt/esplora_volume ext4 defaults,noatime,nofail 0 2" | sudo tee -a /etc/fstab

# set esplora directory. Disk containing this directory needs to be large enough to contain the block data for bitcoin full node (~400GB for mainnet as of 8/12/2021)
# as well as the blockstream/esplora index, which is around ~800GB when fully compacted (~400gb for lightmode), so might need 1.6TB or more during sync/indexing.
# As time passes this may increase

# Specify the directory you're installing esplora to. Ensure it has the space requirements outlined above
# if using gcp and mounted drive use /mnt/sdb
dir=/mnt/disks/sdb


#update apt and install docker
sudo apt-get update -y
sudo apt-get install nodejs npm -y
sudo apt-get install htop -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# docker-machine
# base=https://github.com/docker/machine/releases/download/v0.16.0 \
#  && curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine \
#  && sudo mv /tmp/docker-machine /usr/local/bin/docker-machine \
#  && chmod +x /usr/local/bin/docker-machine

# gitlab runner
# arch=amd64
# curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
# sudo apt-get install gitlab-runner -y
#
# above seems better
# curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb"
# sudo dpkg -i gitlab-runner_amd64.deb

# install git, clone into esplora repo
sudo apt-get install -y git
cd $dir
git clone https://github.com/Blockstream/esplora.git
cd esplora

# checkout to commit before UI change. Other changes have also broken script. Keeping here for replicability of script
git checkout e7870ef663622a34a2533563d65c1fb4d27633f7

# copies Blockchain Commons logo to overwrite menu-logo for esplora
curl -o bc_logo.png 'https://www.blockchaincommons.com/images/Borromean-rings_minimal-overlap(256x256).png'
cp bc_logo.png $dir/esplora/www/img/icons/menu-logo.png
cp bc_logo.png $dir/esplora/www/img/favicon.png

# remove other flavors to speed up build time
cd $dir/esplora/flavors
ls --hide=bitcoin-mainnet | xargs -d '\n' rm -rf
cd $dir/esplora

# similar to above, modify Dockerfile to remove liquid, regtest, testnet
# reduces build time for bitcoin mainnet only
sed -i.bak -e '29,49d' Dockerfile
sed -i -e 's/    npm run dist -- bitcoin-mainnet \\/    npm run dist -- bitcoin-mainnet/' Dockerfile

# build docker image and rendering
sudo docker build -t esplora .
npm install
# npm run dist

# install screen and run mainnet container in screen
sudo apt-get install -y screen

# flags for docker run lighter isntance (add to script beloe before debug)
# -e ENABLE_LIGHTMODE=1 -e NO_PRECACHE=1 -e NO_ADDRESS_SEARCH=1


# script to monitor disk size over time, useful for noting max size before compaction
# usually primary disk will be /dev/sda, but if elsewhere, change disk_dir
# or to monitor all disks remove the dir path from the script
disk_dir=/dev/sdb

cat > $dir/esplora/disk_size.sh << EOF
#!/usr/bin/env bash
while [ 1 ]
do
        echo "$(date)" >> hd_size
        df --human-readable $disk_dir >> $dir/esplora/disk_size.log
        sleep 5m
done
EOF

# runs mainnet docker instance, separating from run to send into screen
cat > $dir/esplora/mainnet.sh << EOF
#!/usr/bin/env bash
sudo docker run -e DEBUG=verbose -p 50001:50001 -p 8080:80 --volume $PWD/data_bitcoin_mainnet:/data --rm -i -t esplora bash -c "/srv/explorer/run.sh bitcoin-mainnet explorer"
EOF

# runs mainnet docker instance, separating from run to send into screen
cat > $dir/esplora/run_mainnet.sh << EOF
#!/usr/bin/env bash
sudo screen -dmS mainnet $dir/esplora/mainnet.sh
EOF

# sudo screen -dmS size $dir/esplora/disk_size.sh

# creates service for run_mainnet

# making scripts executable
sudo chmod +x $dir/esplora/run_mainnet.sh
sudo chmod +x $dir/esplora/disk_size.sh
sudo chmod +x $dir/esplora/mainnet.sh


# run script to start instance and create onion address, will restart after pulling out address
$dir/esplora/run_mainnet.sh

# finds onion address from log
onion_v3=$(sudo cat $dir/esplora/data_bitcoin_mainnet/bitcoin/debug.log | grep "tor: Got service ID " | cut -d ' ' -f 9 | tail -1)
#onion_v3="$(sudo cat data_bitcoin_mainnet/bitcoin/debug.log | grep "tor: Got service ID " | cut -d ' ' -f 9 | tail -1 | cut -d ':' -f 1)"


# overwrite mainnet config.env to add onion to flavors and rename titles to BC Esplora
# and rerun docker build + rendering

# copy footer link icons (just using the social links, not using blockstream logos!"
sudo cp -r $dir/esplora/flavors/blockstream/www $dir/esplora/flavors/bitcoin-mainnet/

cat > $dir/esplora/flavors/bitcoin-mainnet/config.env << EOF
#!/bin/bash
export SITE_TITLE='Blockchain Commons Esplora'
export HOME_TITLE='Blockchain Commons Esplora'
export NATIVE_ASSET_LABEL=BTC
export NATIVE_ASSET_NAME=Bitcoin
export MENU_ACTIVE='Bitcoin'
export ONION_V3="http://${onion_v3}"
export FOOTER_LINKS='{
  "/img/github_blue.png": "https://github.com/BlockchainCommons"
}'
EOF

# kill screens and rebuild, then rerun
pkill screen

# rebuilding image/rendering with appended onion address and social links
cd $dir/esplora
sudo docker build -t esplora .
npm run dist

#
sudo bash -c 'cat > /etc/systemd/system/mainnet.service' << EOF
[Unit]
Description=Starts mainnet esplora in screen under root
After=network.target
[Service]
Type=forking
TimeoutStartSec=1
Restart=on-failure
RestartSec=5s
ExecStart=$dir/esplora/run_mainnet.sh
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mainnet
sudo systemctl start mainnet
sudo shutdown -r
