#!/usr/bin/env bash
#
# 
echo "++++++++++ Starting OpsCenter Container ++++++++++++"

cloud_type="gke"
seed_nodes_dns_names=$SEED_NODE_SERVICE
secure_app="yes"

echo "Configuring OpsCenter with the settings:"
echo cloud_type $cloud_type
echo seed_nodes_dns_names $seed_nodes_dns_names
echo secure_app $secure_app

./scripts/opscenter.sh $cloud_type $seed_nodes_dns_names $secure_app

# 100 hours
sleep 360000
#tail -f /var/log/lastlog
