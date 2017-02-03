#!/usr/bin/env bash

seed_node_ip=${1?"Missing seed node IP arg 1"}
cass_user=${2?"Missing user arg 2"}
cass_pass=${3?"Missing pw arg 3"}

sudo tee config.json > /dev/null <<EOF
{
  "cassandra": {
    "seed_hosts": "$seed_node_ip",
    "username": "$cass_user",
    "password": "$cass_pass"
  },
  "cassandra_metrics": {},
  "jmx": {
    "port": "7199"
  }
}
EOF

output="temp"
while [ "${output}" != "\"Test_Cluster\"" ]; do
    output=`curl -X POST http://127.0.0.1:8888/cluster-configs -d @config.json`
    echo $output
done
