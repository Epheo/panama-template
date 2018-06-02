#!/bin/bash

CONSTRAINTS=/opt/openstack/services/neutron/upper-constraints.txt
pip install -c $CONSTRAINTS pymysql networking-onos

source /opt/openstack/osrc/service.osrc
endpoint=`openstack endpoint list -f csv -q |grep neutron`
if [ -z "$endpoint" ]
then
    echo "> Creating sql user and database"
    mysql -h${MYSQL_VIP} -u${MYSQL_USER} -p${MYSQL_PASS} \
          -e "CREATE DATABASE neutron;"
    mysql -h${MYSQL_VIP} -u${MYSQL_USER} -p${MYSQL_PASS} \
          -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
              IDENTIFIED BY '${NEUTRON_DB_PASS}';"
    mysql -h${MYSQL_VIP} -u${MYSQL_USER} -p${MYSQL_PASS} \
          -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
              IDENTIFIED BY '${NEUTRON_DB_PASS}';"

    echo "Creating Neutron user..."
    openstack user create --domain default --password ${NEUTRON_PASS} neutron
    openstack role add --project service --user neutron admin

    echo "> Creating service user and endpoints"
    openstack service create --name neutron \
        --description "OpenStack Networking" network
    openstack endpoint create --region RegionOne \
        network public http://${NEUTRON_VIP}:9696
    openstack endpoint create --region RegionOne \
        network internal http://${NEUTRON_VIP}:9696
    openstack endpoint create --region RegionOne \
        network admin http://${NEUTRON_VIP}:9696
  else
    if [[ $endpoint == *"ERROR"* ]]
    then

      echo "> Cannot connect to Keystone"; exit
    else
      echo "> Endpoint already created"
    fi
fi


echo "> Writing configuration files"
echo "> Using tox-generated config files"

echo "> Configure the metadata agent"
cp /etc/neutron/metadata_agent.ini.sample /etc/neutron/metadata_agent.ini
s='crudini --set /etc/neutron/metadata_agent.ini' # substitute
$s DEFAULT nova_metadata_host $NOVA_VIP
$s DEFAULT metadata_proxy_shared_secret $METADATA_SECRET

echo "> Configure the Compute service to use the Networking service"
s='crudini --set /etc/nova/nova.conf'
$s neutron url http://$NEUTRON_VIP:9696
$s neutron auth_url http://$KEYSTONE_VIP:35357
$s neutron auth_type password
$s neutron project_domain_name default
$s neutron user_domain_name default
$s neutron region_name RegionOne
$s neutron project_name service
$s neutron username neutron
$s neutron password $NEUTRON_PASS
$s neutron service_metadata_proxy true
$s neutron metadata_proxy_shared_secret $METADATA_SECRET

echo '> Configure the server component'
cp /etc/neutron/neutron.conf.sample /etc/neutron/neutron.conf
s='crudini --set /etc/neutron/neutron.conf'
$s database connection \
  "mysql+pymysql://neutron:$NEUTRON_DB_PASS@$MYSQL_VIP/neutron"

$s DEFAULT core_plugin ml2
$s DEFAULT service_plugins networking_onos.plugins.l3.driver:ONOSL3Plugin
$s DEFAULT allow_overlapping_ips true
 
$s DEFAULT transport_url "rabbit://$RABBIT_USER:$RABBIT_PASS@$RABBIT_VIP"
$s DEFAULT auth_strategy keystone
 
$s keystone_authtoken auth_uri http://$KEYSTONE_VIP:5000
$s keystone_authtoken auth_url http://$KEYSTONE_VIP:35357
$s keystone_authtoken memcached_servers $MEMCACHED_VIP:11211
$s keystone_authtoken auth_type password
$s keystone_authtoken project_domain_name default
$s keystone_authtoken user_domain_name default
$s keystone_authtoken project_name service
$s keystone_authtoken username neutron
$s keystone_authtoken password $NEUTRON_PASS
 
$s DEFAULT notify_nova_on_port_status_changes true
$s DEFAULT notify_nova_on_port_data_changes true
 
$s nova auth_url http://$KEYSTONE_VIP:35357
$s nova auth_type password
$s nova project_domain_name default
$s nova user_domain_name default
$s nova region_name RegionOne
$s nova project_name service
$s nova username nova
$s nova password $NOVA_PASS

echo "> Configure the Modular Layer 2 (ML2) plug-in"
cp /etc/neutron/plugins/ml2/ml2_conf.ini.sample \
   /etc/neutron/plugins/ml2/ml2_conf.ini
s='crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini'
$s ml2 type_drivers flat,vlan,vxlan
$s ml2 tenant_network_types vxlan
$s ml2 mechanism_drivers onos_ml2
$s ml2 extension_drivers port_security

$s ml2_type_flat flat_networks provider
$s ml2_type_vxlan vni_ranges 1:1000

$s securitygroup enable_ipset true

$s onos url_path http://$ONOS_VIP:8181/onos/openstacknetworking
$s onos username $ONOS_USER
$s onos password $ONOS_PASS


echo "> Create databases tables"
neutron-db-manage --config-file /etc/neutron/neutron.conf \
                  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini \
                  upgrade head
