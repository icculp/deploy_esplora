# deploy_esplora
Scripts and screenshots for deploying esplora on bitcoin mainnet

Esplora has a number of features that could be useful for a variety of use cases. Depending on how you might need to use it, the resource requirements are different in terms of storage size, disk throughput, IOPS, and RAM, which have some subtleties to keep in mind when deploying in the cloud. Depending on the storage medium, disk throughput can be limited by the bandwidth or IOPS available to simultaneously access files distributed across many drives in the cloud. Attached storage is always faster/lower latency, SSDs are allocated more network throughput, and sometimes having additional CPU's can increase this bandwitdh as well. The constant reading from disk during the indexing process for the blockstream version of electrs is extremely slow without decent IOPS and a good amount of memory. If you are seeking to deploy on minimal resources, the indexing process can take forever, so a few options are outlined below.

Lightmode requires 400gb for bitcoin as of 8/23/2021 and 400GB for the electrs index.
Full requires 400GB and 800GB for electrs index. 


precaching of popular addresses can be run on 2 CPU, 4GB RAM, and a little over 800GB.

Deploy in a large linode instance using 96GB of ram and nearly 2TB SSD, which will take 24-36 hours, then scale down
