#!/bin/bash
#
# 
echo "++++++++++ Starting Cassandra Container With Security ++++++++++++"

cloud_type="gke"
seed_nodes_dns_names=$SEED_NODE_SERVICE
data_center_name=$DATACENTER_NAME
rack_name=$RACK_NAME
opscenter_dns_name=$OPSCENTER_NAME
secure_app="yes"

echo "Configuring nodes with the settings:"
echo cloud_type $cloud_type
echo seed_nodes_dns_names $seed_nodes_dns_names
echo data_center_name $data_center_name
echo rack_name $rack_name
echo opscenter_dns_name $opscenter_dns_name
echo secure_app $secure_app

./scripts/dse.sh $cloud_type $seed_nodes_dns_names $data_center_name $opscenter_dns_name $secure_app $rack_name


#100 hours
sleep 360000
#tail -f /var/log/lastlog
