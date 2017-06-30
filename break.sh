#!/bin/bash
# OpenStack Ceph deployment script for the Red Hat Certified Engineer in Red Hat OpenStack Prep Course
#
# Version 1.0 created 06/27/2017
#
# By Treva N. Williams
#
# This script is provided as a courtesy under the GPL-3.0 license. It comes with no guarantees of
# functionality, no warranties, & is run at-your-own-risk. 
#
# Run this script on the Ceph OSD node in your KVM environment. It will remove
# & destroy ALL data from your previous deployment. Please create backups of
# any Ceph data you want to keep before launching this script.
#
# This script is a work in progress & will be updated frequently. 
#
# purge current config

# initial deploy message
echo "This script will wipe any current ceph deployments before rebooting your
system. When your server comes back online, you will find tasks in motd."
sleep 3
#install ceph-deploy
yum -y install ceph-deploy

sleep 5
#wipe previous ceph data

sudo ceph-deploy purge ceph1 ceph2 ceph3

sleep 3
# purge config files
sudo ceph-deploy purgedata ceph1 ceph2 ceph3

sleep 3 
# remove keyrings
sudo ceph-deploy forgetkeys

sleep 4
#make mount.sh executable
sudo chmod +x /home/ceph/ex310-break/mount.sh

sleep 2
# add mount.sh as cron on reboot
(crontab -l 2>/dev/null; echo "@reboot /home/ceph/ex310-break/mount.sh") crontab -

sleep 5
# reboot to set changes
sleep 5
# clear history 
history -c

sleep 3
#reboot to launch practice exam
sudo systemctl reboot
