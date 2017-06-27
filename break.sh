#!/bin/bash
# OpenStack Ceph deployment script for the Red Hat Engineer in Red Hat OpenStack Prep Course
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


sudo ceph-deploy purge ceph1 ceph2 ceph3
sleep 3
# purge config files
sudo ceph-deploy purgedata ceph1 ceph2 ceph3
sleep 3 
# remove keyrings
sudo ceph-deploy forgetkeys


# reset glance config on controller
#cat config/glance-api.conf | ssh controller tee /etc/glance/glance-api.conf

# Initial deploy message
echo "Reboot all servers in your environment. Using the instructions provided in MOTD, build out your Ceph environment
using whatever deployment method works best for you."

# make follow-up script executable
sudo chmod +x mount.sh
