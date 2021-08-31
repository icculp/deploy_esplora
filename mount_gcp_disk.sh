#!/usr/bin/env bash
sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
sudo mkdir -p /mnt/disks/sdb
sudo mount -o discard,defaults /dev/sdb /mnt/disks/sdb
sudo chmod a+w /mnt/disks/sdb

uuid=$(sudo blkid /dev/sdb | cut -d ' ' -f 2 | cut -d '"' -f 2)

sudo bash -c 'cat >> /etc/fstab' << EOF
UUID=$uuid /mnt/disks/sdb ext4 discard,defaults,nofail 0 2
EOF
