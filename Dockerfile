#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#

FROM debian:7

ENV AEROSPIKE_VERSION 3.5.8
ENV AEROSPIKE_SHA256 b7832823a03d827ba78bc91480f86edbb285b377b9f170d352cbc811ce6a2d51

# Install Aerospike
RUN apt-get update -y
RUN apt-get install -y wget logrotate ca-certificates python
RUN wget "https://www.aerospike.com/artifacts/aerospike-server-community/${AEROSPIKE_VERSION}/aerospike-server-community-${AEROSPIKE_VERSION}-debian7.tgz" -O aerospike-server.tgz
RUN echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c -
RUN mkdir aerospike
RUN tar xzf aerospike-server.tgz --strip-components=1 -C aerospike
RUN dpkg -i aerospike/aerospike-tools-*.deb
RUN apt-get purge -y --auto-remove wget ca-certificates
RUN rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/*

CMD ["/bin/bash"]
