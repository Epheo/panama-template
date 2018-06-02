#!/bin/bash

CONSTRAINTS=/opt/openstack/services/nova/upper-constraints.txt
pip install -c $CONSTRAINTS pymysql

source /opt/openstack/osrc/service.osrc
endpoint=`openstack endpoint list -f csv -q |grep nova`
if [ -z "$endpoint" ]
then

    echo "> Creating sql user and database"
    mysql -h$MYSQL_VIP -u$MYSQL_USER -p$MYSQL_PASS \
          -e "CREATE DATABASE nova_api;"
    mysql -h$MYSQL_VIP -u$MYSQL_USER -p$MYSQL_PASS \
          -e "CREATE DATABASE nova;"
    mysql -h$MYSQL_VIP -u$MYSQL_USER -p$MYSQL_PASS \
          -e "CREATE DATABASE nova_cell0;"

    mysql -h$MYSQL_VIP -u$MYSQL_USER -p$MYSQL_PASS \
          -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
              IDENTIFIED BY '$NOVA_DB_PASS';"
    mysql -h$MYSQL_VIP -u$MYSQL_USER -p$MYSQL_PASS \
          -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
              IDENTIFIED BY '$NOVA_DB_PASS';"

    mysql -h$MYSQL_VIP -u$MYSQL_USER -p$MYSQL_PASS \
          -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
              IDENTIFIED BY '$NOVA_DB_PASS';"
    mysql -h$MYSQL_VIP -u$MYSQL_USER -p$MYSQL_PASS \
          -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
              IDENTIFIED BY '$NOVA_DB_PASS';"

    mysql -h$MYSQL_VIP -u$MYSQL_USER -p$MYSQL_PASS \
          -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' \
              IDENTIFIED BY '$NOVA_DB_PASS';"
    mysql -h$MYSQL_VIP -u$MYSQL_USER -p$MYSQL_PASS \
          -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' \
              IDENTIFIED BY '$NOVA_DB_PASS';"


    echo "> Creating service user and endpoints"
    openstack user create --domain default --password $NOVA_PASS nova
    openstack role add --project service --user nova admin
    openstack service create --name nova \
                             --description "OpenStack Compute" compute
    openstack endpoint create --region RegionOne compute public \
                              http://$NOVA_VIP:8774/v2.1/%\(tenant_id\)s
    openstack endpoint create --region RegionOne compute internal \
                              http://$NOVA_VIP:8774/v2.1/%\(tenant_id\)s
    openstack endpoint create --region RegionOne compute admin \
                              http://$NOVA_VIP:8774/v2.1/%\(tenant_id\)s

    openstack user create --domain default --password $NOVA_PASS placement
    openstack role add --project service --user placement admin
    openstack service create --name placement \
                             --description "Placement API" placement
    openstack endpoint create --region RegionOne placement public \
                              http://$NOVA_VIP:8778
    openstack endpoint create --region RegionOne placement internal \
                              http://$NOVA_VIP:8778
    openstack endpoint create --region RegionOne placement admin \
                              http://$NOVA_VIP:8778

    openstack endpoint list
else
    if [[ $endpoint == *"ERROR"* ]]
    then
      echo "> Cannot connect to Keystone"; exit
    else
      echo "> Endpoint already created"
    fi
fi


echo "> Using tox-generated config files"
cp /etc/nova/nova.conf.sample /etc/nova/nova.conf

echo "> Writing configuration files"
s='crudini --set /etc/nova/nova.conf' # substitute

$s DEFAULT enabled_apis osapi_compute,metadata

$s api_database connection \
  "mysql+pymysql://nova:$NOVA_DB_PASS@$MYSQL_VIP/nova_api"
$s database connection "mysql+pymysql://nova:$NOVA_DB_PASS@$MYSQL_VIP/nova"
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

$s vnc enabled True
$s vnc server_listen $NOVA_VIP
$s vnc server_proxyclient_address $NOVA_VIP

$s glance api_servers "http://$GLANCE_VIP:9292"

$s oslo_concurrency lock_path /var/run/nova

$s placement project_domain_name Default
$s placement project_name service
$s placement auth_type password
$s placement user_domain_name Default
$s placement auth_url "http://$KEYSTONE_VIP:35357/v3"
$s placement username placement
$s placement password $NOVA_PASS


echo "> Updating database tables"
nova-manage api_db sync
nova-manage cell_v2 map_cell0
nova-manage cell_v2 create_cell --name=cell1 --verbose
nova-manage db sync


echo "[Done]"
