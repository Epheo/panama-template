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

config = ConfigParser()

configfile = '/etc/glance/glance-api.conf'
config.read(configfile)

config['database']['connection'] = 'mysql://glance:%s@%s/glance' % (os.environ.get('GLANCE_DBPASS'),
                                                                    os.environ.get('HOST_IP'))

config['keystone_authtoken']['auth_uri'] = 'http://%s:5000/v2.0' % os.environ.get('HOST_IP')
config['keystone_authtoken']['identity_uri'] = 'http://%s:35357' % os.environ.get('HOST_IP')
config['keystone_authtoken']['admin_tenant_name'] = 'service'
config['keystone_authtoken']['admin_user'] = 'glance'
config['keystone_authtoken']['admin_password'] = os.environ.get('GLANCE_PASS')

config['paste_deploy']['flavor'] = 'keystone'

config['glance_store']['default_store'] = 'file'
config['glance_store']['filesystem_store_datadir'] = '/var/lib/glance/images/'

config['DEFAULT']['notification_driver'] = 'noop'

config['DEFAULT']['verbose'] = 'True'

print('Parsing of %s...' % configfile)
with open(configfile, 'w') as configfile:
    config.write(configfile)
print('Done')

####

configfile = '/etc/glance/glance-registry.conf'
config.read(configfile)

config['database']['connection'] = 'mysql://glance:%s@%s/glance' % (os.environ.get('GLANCE_DBPASS'),
                                                                    os.environ.get('HOST_IP'))

config['keystone_authtoken']['auth_uri'] = 'http://%s:5000/v2.0' % os.environ.get('HOST_IP')
config['keystone_authtoken']['identity_uri'] = 'http://%s:35357' % os.environ.get('HOST_IP')
config['keystone_authtoken']['admin_tenant_name'] = 'service'
config['keystone_authtoken']['admin_user'] = 'glance'
config['keystone_authtoken']['admin_password'] = os.environ.get('GLANCE_PASS')

config['paste_deploy']['flavor'] = 'keystone'

config['DEFAULT']['notification_driver'] = 'noop'

config['DEFAULT']['verbose'] = 'True'

print('Parsing of %s...' % configfile)
with open(configfile, 'w') as configfile:
    config.write(configfile)
print('Done')