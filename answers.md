#Red Hat Engineer in Red Hat OpenStack Practice exam


##<a name="one">1. Install Ceph</a>

##Using ceph-ansible

* Edit all.yml to point to Ceph Kraken repository

````
ceph_origin: upstream
...
ceph_stable: true
ceph_mirror: http://download.ceph.com
ceph_stable_key: https://download.ceph.com/keys/release.asc
ceph_stable_release: kraken
ceph_stable_repo: https://download.ceph.com/rpm-kraken/el7/x86_64
ceph_stable_redhat_distro: el7
...
#OPTIONAL
# -----
cephx: true
# ----
monitor_interface: $NETWORK
monitor_address: $SERVER_IP
ip_version: ipv4
journal_size: 10240
public_network: $SERVER_IP/24
````
* osds.yml

````
# CEPH OPTIONS

    - /mnt/ex310

journal_collocation: true
````
 
##Using ceph-deploy
 

* create ceph cluster

````
ceph-deploy new ceph1 ceph2 ceph3
````

* install ceph

````
ceph-deploy install ceph1 ceph2 ceph3
````

* Deploy ceph monitors & OSDs

````
ceph-deploy install --mon ceph1 ceph2 ceph3
ceph-deploy install --osd ceph1 ceph2 ceph3
ceph-deploy mon create ceph2
````
* collect initial keyrings on admin node

````
ceph-deploy gatherkeys ceph1
````
* Convert ceph1 into an admin node

````
ceph-deploy admin ceph1
````

* from admin node: prepare /mnt/ex310 for ceph deployment

````
ceph-deploy osd zap ceph1:/mnt/ex310 ceph2:/mnt/ex310 ceph3:/mnt/ex310
ceph-deploy osd prepare ceph1:/mnt/ex310 ceph2:/mnt/ex310 ceph3:/mnt/ex310
````
* Activate OSDs

````
ceph-deploy osd activate ceph1:/mnt/ex310 ceph2:/mnt/ex310 ceph3:/mnt/ex310
````
##<a name="two">2 - Add Ceph as Glance backend</a>

+ Create Ceph RBD pool for Glance images on ceph1

````
ceph osd pool create images 32
````

+ **IF CEPHX IS ENABLED:** Create the keyring that will allow Glance access to
pool

````
ceph auth get-or-create client.images mon 'allow r' osd 'allow class-read
object_prefix rdb_children, allow rwx pool=images' -o
/etc/ceph/ceph.client.images.keyring
````

+ Copy the keyring to /etc/ceph on OpenStack controller

````
# scp /etc/ceph/ceph.client.images.keyring root@controller:/etc/ceph
````

* Copy ceph config file to controller
````
$ scp /etc/ceph/ceph.conf root@controller:/etc/ceph
````

+ Set permissions on controller so Glance can access Ceph keyring

````
# chgrp glance /etc/ceph/ceph.client.images.keyring
# chmod 0640 /etc/ceph/ceph.client.images.keyring
````
+ Add keyring file to Ceph config

````
# vim /etc/ceph/ceph.conf

...
[client.images]
keyring = /etc/ceph/ceph.client.images.keyring
````
+ Backup original Glance config

````
# cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.orig
````

+ Update /etc/glance/glance-api.conf

````
...
 [glance_store]
stores = glance.store.rbd.Store
default_store = rbd
rbd_store_pool = images
rbd_store_user = images
rbd_store_ceph_conf = /etc/ceph/ceph.conf
````
+ Restart Glance

````
# systemctl restart openstack-glance-api
````
##<a name="three">3 - Create fedora-atomic image</a>

* Download image from https://getfedora.org/en/atomic/download/
* Upload image in .raw format using OpenStack CLI

````
openstack image create fedora-atomic --disk-format raw --container-format bare
--public --file /path/to/fedora-atomic-latest.raw
````
* verify upload in Ceph RBD pool

````
rbd info /$(sudo rbd ls images)
````
##<a name="four">4 - Create Cinder volume</a>

````
openstack volume create cephalopod --size 5 --type ceph --project rainbow
````

##<a name="five">5 - Adding Projects</a>

* create rainbow project

````
openstack project create --description "Rainbow project" rainbow
````
* create users

````
for i in rose orenthal yolanda gene britney ivan victoria;
do
openstack user create --project rainbow --password openstack $i
done
````

##<a name="six">6 - Adding Ceph as a backend for Cinder</a>

* Create a new OSD pool for cinder

````
ceph osd pool create volumes 32
````

* IF USING CEPHX: create keyring for volumes user

````
ceph auth get-or-create client.volumes mon 'allow r' osd 'allow class-read
object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images' -o
/etc/ceph/ceph.client.volumes.keyring
````

* copy keyring to OpenStack controller

````
scp /etc/ceph/ceph.client.volumes.keyring root@controller:/etc/ceph
````

* Create cinder authentication key

````
ceph auth get-key client.volumes | ssh controller tee client.volumes.key
````

* Set needed permissions on keyring file to allow access by Cinder

````
# chgrp cinder /etc/ceph/ceph.client.volumes.keyring
# chmod 0640 /etc/ceph/ceph.client.volumes.keyring
````

* Add the keyring to ceph configuration file on OpenStack controller
    * edit /etc/ceph/ceph.conf

````
...
[client.volumes]
keyring = /etc/ceph/ceph.client.volumes.keyring
````

* Give KVM hypervisor access to ceph

````
# uuidgen |tee /etc/ceph/cinder.uuid.txt
````

+ scp contents of /etc/ceph/ to compute node:

````
# scp /etc/ceph/* root@compute1:/etc/ceph/
````

* On compute node, create a secret in virsh so KVM can access ceph pool for
* cinder volumes
    * edit /etc/ceph/cinder.xml

````
<secret ephemeral="no" private="no">
 <uuid>ce6d1549-4d63-476b-afb6-88f0b196414f</uuid>
 <usage type="ceph">
 <name>client.volumes secret</name>
 </usage>
</secret>
````

````
# virsh secret-define --file /etc/ceph/cinder.xml
````
````
# virsh secret-set-value --secret ce6d1549-4d63-476b-afb6-88f0b196414f \
    --base64 $(cat /etc/ceph/client.volumes.key)
````
* Add ceph backend for Cinder
    * edit /etc/cinder/cinder.conf

````
...
[DEFAULT]
...
enabled_backends = ceph

[rbd]
volume_driver = cinder.volume.drivers.rbd.RBDDriver
rbd_pool = volumes
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_flatten_volume_from_snapshot = false
rbd_max_clone_depth = 5
rbd_store_chunk_size = 4
rados_connect_timeout = -1
glance_api_version = 2
rbd_user = volumes
rbd_secret_uuid = 00000000-00000000-00000000 # This should be the same as the
secret set in /etc/ceph/cinder.xml
````

* Restart cinder on controller

````
# openstack-service restart cinder
````

* create ceph volume backend in Cinder

````
# openstack volume type create --property volume_backend_name=RBD CEPH
````

##<a name="seven">7 - Create a new, public network for the Rainbow project

* Create an external network

````
openstack network create prism -–external
````

* Create subnet

````
openstack subnet create \
--allocation-pool start=172.24.1.100,end=172.24.1.199 \
--gateway 172.24.1.1 --no-dhcp --network prism \
--subnet-range 172.24.1.0/24 --dns-nameserver 8.8.8.8 prism-sub
````
##<a name="eight">8 - Create Server Flavors</a>

* c1.small

````
openstack flavor create c1.small --ram 1024 --disk 10 --ephemeral 20 --vcpus 1
````

* c1.med

````
openstack flavor create c2.web --ram 2048 --disk 12 --ephemeral 40 --vcpus 2
````

##<a name="nine">9 - Add Ceph as a backend for Nova</a>

* On ceph admin node (node1) Create ceph pool for nova

````
$ sudo ceph osd pool create vms 64
````

* create an authentication ring for nova on ceph admin node

````
$ sudo ceph auth get-or-create client.nova mon 'allow r' osd \
    'allow class-read object_prefix rbd_children, allow rwx pool=vms, \
    allow rx pool=images' -o /etc/ceph/ceph.client.nova.keyring
````

* Copy the keyring to Openstack controller(s)

````
$ scp /etc/ceph/ceph.client.nova.keyring root@controller:/etc/ceph
````

* Create key file on OpenStack controller(s)
    + creates as ceph user

````
$ sudo ceph auth get-key client.nova |ssh controller tee client.nova.key
````

##OpenStack Controller

* set permissions of the keyring file to allow access by Nova

````
# chgrp nova /etc/ceph/ceph.client.nova.keyring
# chmod 0640 /etc/ceph/ceph.client.nova.keyring
````

* Verify correct packages are installed (???)

````
# yum list installed python-rbd ceph-common
````

* Update ceph config
    + edit /etc/ceph/ceph.conf

````
...
[client.nova]
keyring = /etc/ceph/ceph.client.nova.keyring
````

* Give KVM access to ceph

````
# uuidgen |tee /etc/ceph/nova.uuid.txt
````

* Create a secret in virsh so KVM can access the ceph pool for cinder volumes
    * generate a new secret with uuidgen
    * edit /etc/ceph/nova.xml

````
<secret ephemeral="no" private="no">
<uuid>c89c0a90-9648-49eb-b443-c97adb538f23</uuid>
<usage type="ceph">
<name>client.volumes secret</name>
</usage>
</secret>
````

````
# virsh secret-define --file /etc/ceph/nova.xml
````

````
# virsh secret-set-value --secret c89c0a90-9648-49eb-b443-c97adb538f23 \
    --base64 $(cat /etc/ceph/client.nova.key)
````

* Create backup of nova.conf

````
# cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
````

* Update nova.conf to use ceph backend
    * edit /etc/nova/nova.conf

````
...
force_raw_images = True
disk_cachemodes = writeback
...
[libvirt]
images_type = rbd
images_rbd_pool = vms
images_rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = nova
rbd_secret_uuid = c89c0a90-9648-49eb-b443-c97adb538f23
````

* Restart nova

````
# systemctl restart openstack-nova-compute
````

##<a name="ten"> 10 - New Servers for Rainbow project</a>

* Create server

````
openstack server create webserver --flavor c1.small --image=‘fedora-atomic’
--nic net-id=$PRISM-INTERNAL-UUID --wait 
````

* Add webserver to the web-lb loadbalancer pool

````
neutron lbaas-member-create –subnet ex310k-sub \
--address 192.168.1.3 --protocol-port 80 web-lb-pool
````

##<a name="eleven">11 - Add floating IP to webserver</a>

* Generate floating IP address

````
openstack floating ip create prism --floating-ip-address=172.24.1.140
````

* Add IP to webserver

````
openstack server add floating ip webserver 172.24.1.140
````

##<a name="twelve">12 - Create webserver2 </a>

* Create server

````
openstack server create webserver2 --flavor c1.small --image=‘fedora-atomic’
--nic net-id=$PRISM-INTERNAL-UUID --wait 
````

* Add webserver to the web-lb loadbalancer pool

````
neutron lbaas-member-create –subnet ex310k-sub \
--address 192.168.1.3 --protocol-port 80 web-lb-pool
````

##<a name="thirteen">13 - Security Groups</a>

* Create a new security group

````
openstack security group create webserver-sg --description “ex310k security
group” 
````

* add security group rules for HTTP, HTTPS, SSH, & ping

````
openstack security group rule create webserver-sg --protocol tcp --dst-port
22:22 --src-ip 0.0.0.0/0
openstack security group rule create webserver-sg --protocol tcp --dst-port
80:80 --src-ip 0.0.0.0/0
openstack security group rule create webserver-sg --protocol tcp --dst-port
443:443 --src-ip 0.0.0.0/0
openstack security group rule create webserver-sg --protocol icmp --src-ip
0.0.0.0/0
````

##<a name="fourteen">14 - Create a load balancer</a>

* Create a load balancer

````
openstack subnet list
neutron lbaas-loadbalancer-create --name web-lb prism-internalsub
````

* Create LB listeners

````
neutron lbaas-listener-create --name weblb-listener --loadbalancer web-lb
--protocol HTTP --protocol-port 80
neutron lbaas-listener-create --name weblb-listener --loadbalancer web-lb
--protocol HTTP --protocol-port 443
````
* Create a load balancer pool

````
neutron lbaas-pool-create --name weblb-pool --lb-algorithm ROUND_ROBIN
--listener weblb-listener --protocol HTTP 
````

* Add members to weblb-pool

````
openstack server list
neutron lbaas-member-create --subnet prism-internalsub --address $WEBSERVER-IP
--protocol-port 80 weblb-pool
neutron lbaas-member-create --subnet prism-internalsub --address
$WEBSERVER2-IP --protocol-port 80 weblb-pool
````

##<a name="fifteen">15 - LBaaS health monitors </a>

````
neutron lbaas-healthmonitor-create --delay 30 --type HTTP --max-retries 5
--timeout 10 --type HTTP --pool  weblb-pool
````

##<a name="sixteen">Add Floating IP to LBaaS instance</a>

* Create Floating IP address

````
openstack floating ip create prism --floating-ip-address=172.24.1.170
````

* Locate Neutron port for web-lb

````
openstack port list
````

* Add floating IP to web-lb port

````
neutron floatingip-associate $FLOAT-ID $LB-PORT-ID
````

##<a name="seventeen">17 - Internal Networks</a>

* Create a new, private network named prism-internal

````
openstack network create prism-internal
````

* Create new subnet for the prism-internal network named prism-internalsub on
* the 192.168.10.0/24

````
openstack subnet create --network prism-internal --subnet-range
192.168.10.0/24 prism-internalsub
````

##<a name="eighteen">18 - Debian Stretch Image</a>

* download Debian Stretch image from
* http://cdimage.debian.org/cdimage/openstack/current-9/
* convert from .qcow2 to .raw format

````
qemu-img convert /path/to/debian-9-openstack-amd64.qcow2
/path/to/debian-9-openstack-amd64.raw
````

* create image

````
openstack image create debian-stretch --disk-format raw --container-format
bare --project rainbow --file /path/to/debian-9-openstack-amd64.raw 
````

##<a name="nineteen">19 - Persistent Linux Bridges</a>

* Add 192.168.10.84 to the network server node

````
ip addr add 192.168.10.84/24 dev br310
````

* create ifcfg-br310 under /etc/sysconfig/network-scripts with the following:

````
DEVICE=“br310”
TYPE=“Bridge”
BOOTPROTO=“static”
IPADDR=“192.168.10.84”
NETMASK=“255.255.255.0”
GATEWAY=“$YOUR-GW”
ONBOOT=“yes”
NM_CONTROLLED=“no”
````
