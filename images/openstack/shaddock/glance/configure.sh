#!/bin/bash

CONSTRAINTS=/opt/openstack/services/glance/upper-constraints.txt
pip install -c $CONSTRAINTS pymysql
pip install -c $CONSTRAINTS python-memcached

source /opt/openstack/osrc/service.osrc
if [ -z `openstack prject list -f csv -q |grep service` ]
then
      openstack project create service
fi
endpoint=`openstack endpoint list -f csv -q |grep glance`
if [ -z "$endpoint" ]
then

    echo "> Creating sql user and database"
    mysql -h${MYSQL_VIP} -u${MYSQL_USER} -p${MYSQL_PASS} \
          -e "CREATE DATABASE glance;"
    mysql -h${MYSQL_VIP} -u${MYSQL_USER} -p${MYSQL_PASS} \
          -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
              IDENTIFIED BY '${GLANCE_DB_PASS}';"
    mysql -h${MYSQL_VIP} -u${MYSQL_USER} -p${MYSQL_PASS} \
          -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
              IDENTIFIED BY '${GLANCE_DB_PASS}';"

    echo "> Creating Glance user"
    openstack user create --domain default --password ${GLANCE_PASS} glance
    openstack role add --project service --user glance admin

    echo "> Creating service user and endpoints"
    openstack service create --name glance \
        --description "OpenStack Image" image
    openstack endpoint create --region RegionOne \
        image public http://${GLANCE_VIP}:9292
    openstack endpoint create --region RegionOne \
        image internal http://${GLANCE_VIP}:9292
    openstack endpoint create --region RegionOne \
        image admin http://${GLANCE_VIP}:9292

else

    if [[ $endpoint == *"ERROR"* ]]; then
      echo "> Cannot connect to Keystone"; exit
    else
      echo "> Endpoint already created"
    fi
fi


echo "> Writing configuration files"
CRUDINI='crudini --set /etc/glance/glance-api.conf'

$CRUDINI database \
  connection "mysql+pymysql://glance:$GLANCE_DB_PASS@$MYSQL_VIP/glance"

$CRUDINI keystone_authtoken auth_uri "http://$KEYSTONE_VIP:5000"
$CRUDINI keystone_authtoken auth_url "http://$KEYSTONE_VIP:35357"
$CRUDINI keystone_authtoken memcached_servers $MEMCACHED_VIP:11211
$CRUDINI keystone_authtoken auth_type password
$CRUDINI keystone_authtoken project_domain_name default
$CRUDINI keystone_authtoken user_domain_name default
$CRUDINI keystone_authtoken project_name service
$CRUDINI keystone_authtoken username glance
$CRUDINI keystone_authtoken password $GLANCE_PASS

$CRUDINI paste_deploy flavor keystone

$CRUDINI glance_store stores file,http
$CRUDINI glance_store default_store file
$CRUDINI glance_store filesystem_store_datadir '/var/lib/glance/images/'


CRUDINI='crudini --set /etc/glance/glance-registry.conf'

$CRUDINI database connection \
  "mysql+pymysql://glance:$GLANCE_DB_PASS@$MYSQL_VIP/glance"

$CRUDINI keystone_authtoken auth_uri "http://$KEYSTONE_VIP:5000"
$CRUDINI keystone_authtoken auth_url "http://$KEYSTONE_VIP:35357"
$CRUDINI keystone_authtoken memcached_servers $MEMCACHED_VIP:11211
$CRUDINI keystone_authtoken auth_type password
$CRUDINI keystone_authtoken project_domain_name default
$CRUDINI keystone_authtoken user_domain_name default
$CRUDINI keystone_authtoken project_name service
$CRUDINI keystone_authtoken username glance
$CRUDINI keystone_authtoken password $GLANCE_PASS

$CRUDINI paste_deploy flavor keystone


echo "> Updating database tables"
glance-manage db_sync


echo "[Done]"
