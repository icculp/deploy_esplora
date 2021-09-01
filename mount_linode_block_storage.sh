#!/usr/bin/env bash
# if you name the block storage volume something else, change this below
volume_name=esplora_volume

sudo mkfs.ext4 "/dev/disk/by-id/scsi-0Linode_Volume_${volume_name}"
sudo mkdir "/mnt/${volume_name}"
sudo mount "/dev/disk/by-id/scsi-0Linode_Volume_${volume_name}" "/mnt/${volume_name}"

# ensure mount on boot
echo "/dev/disk/by-id/scsi-0Linode_Volume_${volume_name} /mnt/${volume_name} ext4 defaults,noatime,nofail 0 2" | sudo tee -a /etc/fstab
