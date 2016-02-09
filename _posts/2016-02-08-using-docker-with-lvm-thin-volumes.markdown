---
layout: post
title: "Using FireFox to play video with Mplayer on Windows"
date: 2016-01-31 16:30:00 +0300
tags: firefox mplayer youtube mpv video
commentIssueId: 5
---

[root@ ]# lvconvert --type thin-pool --poolmetadata docker/docker-pool-meta docker/docker-pool-data
  WARNING: Maximum supported pool metadata size is 16,00 GiB.
  WARNING: Converting logical volume docker/docker-pool-data and docker/docker-pool-meta to pool's data and metadata volumes.
  THIS WILL DESTROY CONTENT OF LOGICAL VOLUME (filesystem etc.)
Do you really want to convert docker/docker-pool-data and docker/docker-pool-meta? [y/n]: y
  Volume group "docker" has insufficient free space (0 extents): 38102 required.

[root@ ]# vgs -o +vg_free_count,vg_extent_count
  VG     #PV #LV #SN Attr   VSize   VFree  Free #Ext
  centos   1   3   0 wz--n- 930,51g 60,00m   15 238210
  docker   1   2   0 wz--n- 744,18g     0     0 190511

[root@ ]# lvcreate -n docker-pool-meta -l 20%VG docker
  Logical volume "docker-pool-meta" created.

[root@ ]# lvremove docker/docker-pool-data
  Logical volume "docker-pool-data" successfully removed

[root@ ]# lvcreate -n docker-pool-data -l 114307 docker
  Logical volume "docker-pool-data" created.

[root@ ]# lvs
  LV               VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  home             centos -wi-ao---- 876,45g
  root             centos -wi-ao----  50,00g
  swap             centos -wi-a-----   4,00g
  docker-pool-data docker -wi-a----- 446,51g
  docker-pool-meta docker -wi------- 148,84g
[root@ ]# lvconvert --type thin-pool --poolmetadata docker/docker-pool-meta docker/docker-pool-data
  WARNING: Maximum supported pool metadata size is 16,00 GiB.
  WARNING: Converting logical volume docker/docker-pool-data and docker/docker-pool-meta to pool's data and metadata volumes.
  THIS WILL DESTROY CONTENT OF LOGICAL VOLUME (filesystem etc.)

ExecStart=/usr/bin/docker daemon -H unix:///run/docker.sock -H tcp://0.0.0.0:2375 --dns=172.17.0.1 --storage-driver=devicemapper --storage-opt dm.thinpooldev=/dev/mapper/docker-docker--pool--data --storage-opt=dm.use_deferred_removal=true --storage-opt=dm.mountopt=noatime --storage-opt=dm.fs=xfs

