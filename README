#README
OpenStack Ceph deployment script for the Red Hat Certified Engineer in Red Hat OpenStack
Prep Course

Version 1.0 created 06/27/2017

 By Treva N. Williams

This script is provided as a courtesy under the GPL-3.0 license. It comes with
no guarantees of functionality, no warranties, and is run at-your-own-risk.

Run this script on the Ceph OSD node in your KVM environment. It will remove
and destroy ALL data from your previous deployment. Please create backups of
any Ceph data you want to keep before launching this script. 

#DO NOT EXECUTE THIS SCRIPT DIRECTLY ON YOUR WORKSTATION.

This script is a work in progress and will be updated frequently.

In order to perform this lab you will need a two-node OpenStack environment
running Nova, Neutron, Cinder, Swift, and Glance services at minimum, and at
least three nodes (admin, mon, osd) for Ceph deployment. The script should be
launched as the ceph user with preconfigured, elevated privileges as
demonstrated in the Linux Academy ex310k course. 

#instructions
1. Clone the repository to the Ceph user's home directory under /home/ceph/. 
---
cd /home/ceph/
git clone https://github.com/OGtrilliams/ex310k-break
---
2. Make break.sh executable
---
sudo chmod +x /home/ceph/ex310k-break/break.sh
---
3. Execute break.sh as the Ceph user
---
cd ex310k-break 
./break.sh
---
4. Allow the script to run. Your system will reboot after deployment
completes. Exam instructions can be found in /etc/motd

