FROM ubuntu:14.04
MAINTAINER Thibaut Lapierre <root@epheo.eu>

# HP intern specific Proxy configuration
ENV http_proxy 	http://proxy.sdc.hp.com:8080/
ENV https_proxy https://proxy.sdc.hp.com:8080/
ENV no_proxy 	'gerrit.hpcloud.net'
ENV HOME /root

ADD 01proxies /etc/apt/apt.conf.d/01proxies


# OpenStack Repo and packages
RUN apt-get -y update

RUN apt-get -y install ubuntu-cloud-keyring
RUN echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list

RUN apt-get -y update && apt-get -y dist-upgrade

RUN apt-get -y install supervisor wget python-pip mysql-client mysql-common python-mysqldb