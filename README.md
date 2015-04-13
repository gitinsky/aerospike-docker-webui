# Aerospike 

based on https://github.com/aerospike/aerospike-server.docker

# Using this Image

```
sudo docker build -t gitinsky/aerospike-binstore https://github.com/gitinsky/aerospike-docker-binstore.git

for ii in data logs commitlog saved_caches; do sudo mkdir -vp /storage/aerospike-binstore/$ii; done

sudo docker run \
  -e MEM_PC_FAST=10 \
  -e MEM_PC_BIG=70 \
  -e CLUSTER_ADDRS="comma separated list of addresses" \
  -e NODE_EXT_ADDR="$(ip addr show dev eth0|grep -P '^\s*inet\s+'|tr '/' ' '|awk '{print $2}')" \
  -e NODE_INT_ADDR="$(ip addr show dev eth1|grep -P '^\s*inet\s+'|tr '/' ' '|awk '{print $2}')" \
  -p 3000:3000 -p 3001:3001 -p 3002:3002 -p 3003:3003 \
  -v /storage/data:/storage/data \
  -v /storage/logs:/storage/logs \
  -t -i gitinsky/aerospike-binstore
```
