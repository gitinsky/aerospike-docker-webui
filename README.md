# Aerospike 

based on https://github.com/gitinsky/aerospike-docker-binstore.git

# Using this Image

```
sudo docker build -t gitinsky/aerospike-webui https://github.com/gitinsky/aerospike-docker-webui.git

sudo docker run \
  -e BIND_ADDR="127.0.0.1" \
  -e BIND_PORT="8081" \
  -p 8081:8081 \
  -v /storage/aerospike-webui/logs:/storage/logs \
  --net=host \
  -t -i gitinsky/aerospike-webui
```
