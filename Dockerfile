#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#

FROM debian:7

ENV AEROSPIKE_VERSION 3.5.4
ENV AEROSPIKE_SHA256 0e055873632a278b5974b5db12c32a3912f2166ae1f0a7ed58271f9f4c19afc9

# Install Aerospike
RUN apt-get update -y
RUN apt-get install -y wget logrotate ca-certificates gcc python python-dev
RUN wget "http://www.aerospike.com/download/amc/${AEROSPIKE_VERSION}/artifact/debian6" -O amc-server.deb
RUN echo "$AEROSPIKE_SHA256 *amc-server.deb" | sha256sum -c -
RUN dpkg -i amc-server.deb
RUN apt-get purge -y --auto-remove wget ca-certificates
RUN rm -rf amc-server.deb /var/lib/apt/lists/*

VOLUME ["/storage/logs"]

EXPOSE 8081

CMD ["/bin/bash"]
