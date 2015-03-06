#!/usr/bin/env python
# -*- coding: utf-8 -*-

#    Copyright (C) 2014 Thibaut Lapierre <root@epheo.eu>. All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from configparser import ConfigParser
import os

configfile = '/etc/nova/nova.conf'
config = ConfigParser()
config.read(configfile)

config['database']['connection'] = 'mysql://nova:%s@%s/nova' % (os.environ.get('NOVA_DBPASS'),
                                                                os.environ.get('HOST_IP'))

config['DEFAULT']['rpc_backend'] = 'rabbit'
config['DEFAULT']['rabbit_host'] = os.environ.get('HOST_IP')
config['DEFAULT']['rabbit_password'] = os.environ.get('RABBIT_PASS')

config['DEFAULT']['auth_strategy'] = 'keystone'

config['keystone_authtoken']['auth_uri'] = 'http://%s:5000/v2.0' % os.environ.get('HOST_IP')
config['keystone_authtoken']['identity_uri'] = 'http://%s:35357' % os.environ.get('HOST_IP')
config['keystone_authtoken']['admin_tenant_name'] = 'service'
config['keystone_authtoken']['admin_user'] = 'nova'
config['keystone_authtoken']['admin_password'] = os.environ.get('NOVA_PASS')

config['DEFAULT']['my_ip'] = os.environ.get('HOST_IP')

config['DEFAULT']['vncserver_listen'] = os.environ.get('HOST_IP')
config['DEFAULT']['vncserver_proxyclient_address'] = os.environ.get('HOST_IP')

config['glance']['host'] = os.environ.get('HOST_IP')

config['DEFAULT']['verbose'] = 'True'

print('Parsing of %s...' % configfile)
with open(configfile, 'w') as configfile:
    config.write(configfile)
print('Done')