#!/bin/bash
# Script to mount disk on /mnt/ex310k
#
# v1.0
#
mkdir -p /mnt/ex310
sleep 2

# List mounted disks

DISK=$(fdisk -l | grep -2 Disk | egrep 'sdb|vdb' | sed s/://g | awk {'print $2'})
sudo mkfs.xfs $DISK && mount $DISK /mnt/ex310
sleep 5
tail -n 1 /etc/mtab >> /etc/fstab

# delete history

history -c

