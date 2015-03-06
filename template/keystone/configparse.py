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

configfile = '/etc/keystone/keystone.conf'
config = ConfigParser()
config.read(configfile)

config['DEFAULT']['admin_token'] = os.environ.get('ADMIN_TOKEN')

config['database']['connection'] = 'mysql://keystone:%s@%s/keystone' % (os.environ.get('KEYSTONE_DBPASS'),
                                                                        os.environ.get('HOST_IP'))

config['token']['provider'] = 'keystone.token.providers.uuid.Provider'
config['token']['driver'] = 'keystone.token.persistence.backends.sql.Token'
config['revoke']['driver'] = 'keystone.contrib.revoke.backends.sql.Revoke'
config['DEFAULT']['verbose'] = 'True'

print('Parsing of %s...' % configfile)
with open(configfile, 'w') as configfile:
    config.write(configfile)
print('Done')