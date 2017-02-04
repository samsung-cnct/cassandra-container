#!/bin/bash
#
# 
echo "++++++++++ Starting Cassandra Container ++++++++++++"

cloud_type="gke"
seed_nodes_dns_names=$SEED_NODE_SERVICE
data_center_name="dc0"
opscenter_dns_name=$OPSCENTER_NAME

echo "Configuring nodes with the settings:"
echo cloud_type $cloud_type
echo seed_nodes_dns_names $seed_nodes_dns_names
echo data_center_name $data_center_name
echo opscenter_dns_name $opscenter_dns_name

./scripts/dse.sh $cloud_type $seed_nodes_dns_names $data_center_name $opscenter_dns_name 


#100 hours
sleep 360000
#tail -f /var/log/lastlog
