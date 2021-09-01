# deploy_esplora
The primary script in this repo can be used to simplify deployment of Esplora as a docker contanier in a VPS for Bitcoin mainnet. You can run the esplora_setup.sh script in a directory large enough to host the mainnet block data as well as the blockstream version of electrs, which includes an index of transactions allowing for volume level queries without the latency of querying bitcoind on the fly. You can deploy Esplora on any cloud provider or on local hardware. We'll outline a couple of suggestions below. Everything has been configured and tested on Debian 10, but the script could be modified slightly for a deployment on other distros.

## Usage
If you are using a fresh instance on linode, gcloud, aws, or other, you might need to update apt-get and install git.

`sudo apt-get update -y && sudo apt-get install git -y`

Once finished you can clone this repo and the setup script will install everything you need. It can be modified slightly to work in other operating systems but right now it's configured for Debian 10.

`git clone https://github.com/icculp/deploy_esplora.git && cd deploy_esplora`

You can run the script from anywhere, but modify the dir variable to indicate the root of the directory you wish to use, and ensure it's large enough to hold everything (more below on storage requirements)

Script should be modified to take dir as command line argument but for now just modify the script

`dir=/path/large/enough`

So if you're using GCP and you've attached a _standard persistent disk_ (this is the cheapest storage, otherwise if you use other storage types you'd be paying more than using Linode), the dir path would be `/mnt/disks/sdb` (if you've only attached one disk using defaults, which `mount_gcp_disk.sh` can help you with. If you're using Linode, the path would be whatever you named the volume if you used the default mounting configuration provided on the site. For example if you named the volume esplora_mount, you would use `dir=/mnt/esplora_mount`

Then, just run the script. If you copied the script rather than clone the repo, make sure it's executable.

`chmod +x deploy_esplora.sh`

`./deploy_esplora.sh`

This will install gpg, docker, screen, nodejs + npm, and git if not already installed. The script will build and run the docker container in a screen so that you can attach to it and watch the log in realtime if you wish. Additionaly, the script will pull the tor_v3 onion address out of the logs and append it to flavors/bitcoin-mainnet/config.env and rebuild the image and rendering templates. Lastly, it installs the run script as a service and enables the service before restarting to avoid any caching from docker. 

## Sync time
If you are deploying from scratch and you don't mind waiting several weeks, you can deploy on an instance with 8gb of ram and large enough storage and just wait. However, if you need to get it up and running within a couple of days, deploying on an instance with large ~90+GB of ram can finish in 1-3 days depending on the read speed of the drive.

Linode bundles SSD drives as the primary drive of an instance, whereas blockstorage are spinning disk HDDs. On a bundled 96GB instance it'll take about 24 hours from start to finish. On block storage it took about 3 days, relying on the faster memory cache for most reads. They just recently announced a NVMe storage option for block storage at the same price, but I haven't yet tested deployment on there. If you are hoping to sync ASAP then move the data directory to block storage, you'll need to manually reduce the size of the primary disk to be at or below the size mentioned for that instance. Otherwise if you're going to start with block storage and hope for a fast sync, it would be best to crreate the instance as an 8gb shared CPU instance, then upgrade WITHOUT checking the box to automatically scale the disk to avoid having to manually downsize before downgrading the instance back to 8GB. 

## Resource logging
Linode has the longview montoring service, but it costs $20/month for up to three instances. If you use this, they'll give you the command to use to install, but you'll have to manually enable the service afterwards. `sudo systemctl start longview` then `sudo systemctcl status longview` to ensure it's running. 

Google cloud's monitoring agent is free, but it just needs to be installed from the console as follows



You can view the running screens via 

`sudo screen -ls`

Attach to mainnet via 

`sudo screen -r mainnet`

Detach via ctrl-a and then d

Start, stop, or status on the service

`sudo systemctl status|start|stop mainnet`

If it's not running, view logs via 

```
journalctl
journalctl | grep 'error'
journalctl -u mainnet
```


## Resources
Esplora has a number of features that could be useful for a variety of use cases. Depending on how you might need to use it, the resource requirements are different in terms of storage size, disk throughput, IOPS, and RAM, which have some subtleties to keep in mind when deploying in the cloud.

Turns out read speed of the drive may not be the underlying limitation with cloud based VPS's. It's IOPS among distributed cloud storage... Basically, the data is stored in a distributed manner and thus IOPS is limited by network bandwidth, and cloud providers allocate more or less throughput based on the size of the instance you're running, or the region or other factors.

Depending on the storage medium, disk throughput can be limited by the bandwidth or IOPS available to simultaneously access files distributed across many drives in the cloud. Attached storage is always faster/lower latency, SSDs are allocated more network throughput, and sometimes having additional CPU's can increase this bandwitdh as well. The constant reading from disk during the indexing process for the blockstream version of electrs is extremely slow without decent IOPS and a good amount of memory. You can get around this with the slowest storage by having a large amount of memory, allowing for files to be cached and avoiding the latency of reading to disk. Large memory is important especially when you've fallen behind and need to resync the electrs index. 

If you are seeking to deploy on minimal resources, the indexing process can take forever, so you might plan to deploy on an instance with a large amount of memory, then downsize after it's finished syncing. Esplora seems to work well with 8gb of RAM once it's synced, even with precaching of popular addresses. Precaching needs to be disabled if you have lower memory. 

Lightmode requires 400gb for bitcoin as of 8/23/2021 and 400GB for the electrs index.
Full requires 400GB and 800GB for electrs index. 


precaching of popular addresses can be run on 2 CPU, 4GB RAM, and a little over 800GB.

Deploy in a large linode instance using 96GB of ram and nearly 2TB SSD, which will take 24-36 hours, then scale down
## Full inxed on 96GB linode with SSD
Super duper fast

![](https://i.imgur.com/Nk0JVIX.png)
![](https://i.imgur.com/911iJq2.png)

## Full index on 96GB linode with block storage
Notice how the IOPS is limited to mid 500's, but still able to sync within half a week. With low memory this would have taken much longer. Compare to one of the instances with SSD how it spikes up to thousands and can index very quickly. 

![](https://i.imgur.com/stZmaAY.png)
![](https://i.imgur.com/Kt84FU2.png)
![](https://i.imgur.com/J2EhKLn.png)

## Lightmode on linode 96GB and SSD
![](https://i.imgur.com/QgyJu3Q.png)
![](https://i.imgur.com/PGq6kqU.png)

You can get an idea for how quickly you can deploy with these timestamps. You can quickly replicate with full index on fast SSD and large RAM, maybe a few hours longer from scratch. 
![](https://i.imgur.com/IDJT3FT.png)
![](https://i.imgur.com/pElRXLT.png)

# Fullmode on google cloud with standard persistent storage (HDD)
Never finished syncing after weeks. IOPS limited to < 100 which just isn't going to cut it. 
