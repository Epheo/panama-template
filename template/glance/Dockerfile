FROM panama/base:latest
MAINTAINER Thibaut Lapierre <root@epheo.eu>

#install glance
RUN apt-get -y update
RUN apt-get install -y --force-yes glance python-glance python-glanceclient

#Setup supervisord
ADD supervisord.conf /etc/supervisord.conf

VOLUME  ["/var/log/glance"]

ADD glance-start /usr/local/bin/
ADD configparse.py /usr/local/bin/
RUN chmod +x /usr/local/bin/glance-start

EXPOSE 9292
CMD ["glance-start"]
