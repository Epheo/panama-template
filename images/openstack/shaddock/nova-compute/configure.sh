#!/bin/bash

echo "> Writing configuration files"
cp /etc/nova/nova.conf.sample /etc/nova/nova-compute.conf
s='crudini --set /etc/nova/nova-compute.conf'

$s DEFAULT enabled_apis osapi_compute,metadata
$s DEFAULT compute_driver libvirt.LibvirtDriver
$s DEFAULT transport_url "rabbit://$RABBIT_USER:$RABBIT_PASS@$RABBIT_VIP"

$s api auth_strategy keystone

$s keystone_authtoken auth_uri "http://$KEYSTONE_VIP:5000"
$s keystone_authtoken auth_url "http://$KEYSTONE_VIP:35357"
$s keystone_authtoken memcached_servers "$MEMCACHED_VIP:11211"
$s keystone_authtoken auth_type password
$s keystone_authtoken project_domain_name default
$s keystone_authtoken user_domain_name default
$s keystone_authtoken project_name service
$s keystone_authtoken username nova
$s keystone_authtoken password $NOVA_PASS

$s DEFAULT my_ip $NOVA_VIP

$s DEFAULT use_neutron True
$s DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

$s vnc enabled True
$s vnc vncserver_listen 0.0.0.0
$s vnc vncserver_proxyclient_address $NOVA_VIP
$s vnc novncproxy_base_url http://$NOVA_VIP:6080/vnc_auto.html

$s glance api_servers "http://$GLANCE_VIP:9292"

$s oslo_concurrency lock_path /var/run/nova

$s placement os_region_name RegionOne
$s placement project_domain_name Default
$s placement project_name service
$s placement auth_type password
$s placement user_domain_name Default
$s placement auth_url "http://$KEYSTONE_VIP:35357/v3"
$s placement username placement
$s placement password $NOVA_PASS


echo "> Add kvm group"
chown root:kvm /dev/kvm
