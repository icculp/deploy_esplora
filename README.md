# deploy_esplora
Scripts and screenshots for deploying esplora for bitcoin mainnet in Debian 10


Esplora has a number of features that could be useful for a variety of use cases. Depending on how you might need to use it, the resource requirements are different in terms of storage size, disk throughput, IOPS, and RAM, which have some subtleties to keep in mind when deploying in the cloud.

Turns out read speed of the drive may not be the underlying limitation with cloud based VPS's. It's IOPS among distributed cloud storage... Basically, the data is stored in a distributed manner and thus IOPS is limited by network bandwidth, and cloud providers allocate more or less throughput based on the size of the instance you're running, or the region or other factors.

Depending on the storage medium, disk throughput can be limited by the bandwidth or IOPS available to simultaneously access files distributed across many drives in the cloud. Attached storage is always faster/lower latency, SSDs are allocated more network throughput, and sometimes having additional CPU's can increase this bandwitdh as well. The constant reading from disk during the indexing process for the blockstream version of electrs is extremely slow without decent IOPS and a good amount of memory.

If you are seeking to deploy on minimal resources, the indexing process can take forever, so you might plan to deploy on larger resources and move 

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
