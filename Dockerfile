#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#

FROM debian:7

ENV AEROSPIKE_VERSION 3.6.0
ENV AEROSPIKE_SHA256 e88092353a55f0d02f3d5712f100e2aefe6cb808dec032da5cee94991a5a2b37

# Install Aerospike
RUN apt-get update -y
RUN apt-get install -y wget logrotate ca-certificates gcc python python-dev lua5.2
RUN wget "http://www.aerospike.com/download/amc/${AEROSPIKE_VERSION}/artifact/debian6" -O amc-server.deb
RUN echo "$AEROSPIKE_SHA256 *amc-server.deb" | sha256sum -c -
RUN dpkg -i amc-server.deb
RUN apt-get purge -y --auto-remove wget ca-certificates
RUN rm -rf amc-server.deb /var/lib/apt/lists/*

ADD etc/amc/config/gunicorn_config.py.template /etc/amc/config/gunicorn_config.py.template
ADD usr/local/bin/templater.lua /usr/local/bin/templater.lua
ADD usr/local/share/lua/5.2/fwwrt/simplelp.lua /usr/local/share/lua/5.2/fwwrt/simplelp.lua
ADD amc-autoconfig /amc-autoconfig

VOLUME ["/storage/logs"]

EXPOSE 8081

CMD ["/amc-autoconfig"]
