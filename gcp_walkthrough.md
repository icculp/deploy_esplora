# gcloud esplora setup scratch

enable compute api

![](https://i.imgur.com/0bc9Ddi.png)

create instance

![](https://i.imgur.com/01RRVqR.png)

Esplora will run on 8gb, so this instance is the best to select. When syncing from scratch though, I'd recommend starting with a larger instance, like the e2-highmem8

![](https://i.imgur.com/svowW9M.png)

It might take a few days on that instance with standard persistent disk to sync, and incur $0.363 hourly so at 72 hours that would be $26.136 (not including storage) to sync, then downgrade back to the e2-standard-2 (8GB)

click blue arrow link to drop down and add a disk, and network tag for when we open the ports in the firewall
![](https://i.imgur.com/7LuYRRW.png)

click on networking tab and add the tag "esplora" in the box, we'll need this when we configure the firewall rules

![](https://i.imgur.com/DGD2dfi.png)

next, click on disks and add new disk
![](https://i.imgur.com/1idAi4b.png)

we want the standard persistent disk (spinning disk hdd), otherwise you'll spend an arm and a leg...

![](https://i.imgur.com/ndio0rO.png)

name it whatever you want, or leave default disk-1 is fine. I'm setting it to 1250 for now since not syncing from scratch, but copying data over via rsync. If syncing from scratch you could make up to 2TB before reaching the quota for standard persistent disk. Can't request a quota limit while you're in trial credits. From scratch, fullmode goes up to (as of 9/2021) ~1.6Tb before compactnig down to ~1.2TB. Lightmode goes up to 1.2 before compacting to ~800gb

![](https://i.imgur.com/dUsgiPX.png)

![](https://i.imgur.com/5Gcglso.png)

click done to add

Over time you'll probably have to expand the capacity of that drive.

Another interesting note I just discovered, different regions have different pricing. Maybe click through them to see which is the cheapest. 

![](https://i.imgur.com/RlWLCBu.png)

![](https://i.imgur.com/pT6Vvjr.png)

Going to leave it on central-1

once spun up, you can ssh from the console
![](https://i.imgur.com/DnnpciT.png)

git not installed to start so run:
`sudo apt-get update -y && sudo apt-get install git -y`

we can clone the deploy repo, which will have the deploy script, as well as the script to mount the disk we added when creating the instance (it's not autoamically attached in the OS). This script will only work if it's the first and only secondary disk attached to the instance. Otherwise you'd have to slightly modify it, or follow the instructions here:

https://cloud.google.com/compute/docs/disks/add-persistent-disk

now to clone deploy repo and mount the disk
```
git clone https://github.com/icculp/deploy_esplora.git
cd deploy_esplora
./mount_gcp_disk.sh
```

open the `esplora_setup.sh` script and make sure the `dir` variable is set to the directory of the newly mounted disk, large enough to contain the bitcoin block data and the electrs index
`dir=/mnt/disks/sdb`

now we're ready to run the setup script
`./esplora_setup.sh`

this will take a little while to complete, and will restart the instance when it's finally done. So you'll know once the ssh session times out that it should be done.

While this is finishing, we need to open 8080 on the firewall, what we added the esplora tag for.


Open the navigation menu on the left top corner, and scroll down to networking > VPC Network > Firewall (this always takes me a minute to find)

![](https://i.imgur.com/J1yFvVR.png)

create rule

![](https://i.imgur.com/5Eb7VTf.png)

has to start with a letter, I called it in8080

specify the target tag as "esplora" and select ingress (default)

![](https://i.imgur.com/0glUcOX.png)


![](https://i.imgur.com/4zOOrfZ.png)


need to add 0.0.0.0/0 to the specified ip range, then add tcp: 8080. Might need to open 8333 for onion_v3 but I haven't tested that yet. Going to open it now 

![](https://i.imgur.com/rTaXXU8.png)

now we wait till the setup completes. We can go find what external IP has been assigned back at the instance

![](https://i.imgur.com/bWe4BcS.png)

![](https://i.imgur.com/moC92sr.png)

Note, however, that this external IP will change if you stop the instance. Restarts don't change it, but if you actually stop the instance it's likely to change. I've had an instance running for months with the same IP without paying for a static lease, but I could lose it as soon as I stop it, even for a minute.

![](https://i.imgur.com/unyYczd.png)

it's restarting, and soon we'll see the UI live

![](https://i.imgur.com/rbp8kxP.png)


looks like the onionv3 didn't make it...

![](https://i.imgur.com/NMj7ft2.png)

supposed to look like

![](https://i.imgur.com/OfZCRE6.png)

with v3 link...

forcing refresh and it shows up. Since the first build didn't include it as we needed it to build before we could parse the v3 address out of the log, forcing refresh showed the new UI. But, it still didn't get the correct addres...

clicking the link

![](https://i.imgur.com/A3CMF1S.png)

took me to

![](https://i.imgur.com/xqO1xNv.png)

indicating the url is empty... Looking in esplora/flavors/bitcoin-mainnet/config.env, it's not there

![](https://i.imgur.com/lLg7wzc.png)

running `sudo cat data_bitcoin_mainnet/bitcoin/debug.log | grep "tor: Got service ID " | cut -d ' ' -f 9 | tail -1` as the script would have returns the address, not sure why it didn't make it to the file, maybe it wasn't ready yet? Does the hidden service take a while to get the new address? Should this be separated into a script to run after a certain time from the initial setup?

It's there now...
![](https://i.imgur.com/DycfRLH.png)

copied it by hand to the config.env file, and need to rebuild the docker image from the root of the dir, but after stopping the service

```
sudo systemctl stop mainnet
cd $dir/esplora
sudo docker built -t esplora . && npm run dist && sudo shutdown -r
```

when it's done, restart again as docker seems to cache, then after restart make sure the service is started. 

`sudo systemctl status mainnet`

![](https://i.imgur.com/AchYZW7.png)

![](https://i.imgur.com/qsUOIdN.png)

We see it's running! After a force refresh the onvionv3 icon takes us to the onion address! (this still needs to be tested via tor) If you wanted you could leave it as is and it'll eventually sync, but at 8gb it'll take for-freaking-ever. I'm going to copy over rsync all the data from a fully indexed instance.

First though, let's not forget to install the monitoring agent

click on the instance name
![](https://i.imgur.com/3j4nNCY.png)

click observability tab
![](https://i.imgur.com/Hq6Wjpn.png)

click install monitoring agent
![](https://i.imgur.com/qd6D2Ko.png)


click install agent

![](https://i.imgur.com/Ie0VWUz.png)


This will first provision the shell machine (might take a min), and open up a console, once it's open and the command is populated, you need to hit enter to execute it...

![](https://i.imgur.com/fnta28d.png)


hit authorize

![](https://i.imgur.com/1m63CJK.png)

![](https://i.imgur.com/JbTiMFw.png)

that's it, if no errosr, the agent will populate the graphs in this observability tab after a couple minutes

Now to stop service and copy data over rsync

I like to make sure the service is stopped and the docker container isn't running so it won't interfere with the data copy..

![](https://i.imgur.com/qQNSqzP.png)

![](https://i.imgur.com/9OfQbQI.png)

port 22 is open in the firewall by default, but ssh needs the public keys in authorized keys first. You can only do this by first logging into the web ssh client and adding manually. So on this esplora and mine, I generated a key and added it to the others authorized keys

![](https://i.imgur.com/TVeEdez.png)


`sudo apt-get install rsync -y`

Local to Local:  rsync [OPTION]... [SRC]... DEST
Local to Remote: rsync [OPTION]... [SRC]... [USER@]HOST:DEST
Remote to Local: rsync [OPTION]... [USER@]HOST:SRC... [DEST]

so from within the esplora instance, copying from mine, stopping service on both first...

rsync -a --force icculp@35.193.151.192:/mnt/disks/sdb/esplora/data_bitcoin_mainnet /mnt/disks/sdb/esplora/data_bitcoin_mainnet

running into all kinds of trouble with this. Had to chwon the data_bitcoin_mainnet dir for icculp as it was owned by root, and if I ssh'd via root the keys weren't in it's profile, and even after adding them it still was giving me permission denied.

Completed
http://34.135.41.161:8080/

