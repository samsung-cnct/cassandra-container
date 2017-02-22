#!/usr/bin/env bash

echo "Running install-datastax/bin/opscenter.sh dsc21"
 
cloud_type=${1?"Missing cloud type arg 1"}
seed_nodes_dns_names=${2?"Missing seed node names arg 2"}
secure_app=${3:-"yes"}
#
# read passwords off the secret location
#
admin_user="king"
admin_pw=$(</etc/cassandra/foo/AdminPassword)
if [ $? -ne 0 ];then
    echo "ERROR - could not read admin pw"
    exit 3
fi
opscenter_user="opscenter"
opscenter_pw=$(</etc/cassandra/foo/OpsCenterPassword)
if [ $? -ne 0 ];then
    echo "ERROR - could not read opscenter pw"
    exit 3
fi
# Assuming only one seed is passed in for now
seed_node_dns_name=$seed_nodes_dns_names

echo "Waiting for IPs for: $seed_nodes_dns_names ..."
# On GKE we resolve to a private IP.
# On AWS and Azure this gets the public IP.
# On GCE it resolves to a private IP that is globally routeable in GCE.
if [[ $cloud_type == "gke" ]]; then
  # If the IP isn't up yet it will resolve to "" on GKE
  seed_node_ip=""
  while [ "${seed_node_ip}" == "" ]; do
    seed_node_ip=`getent hosts $seed_node_dns_name | awk '{ print $1w }'`
  done
elif [[ $cloud_type == "gce" ]]; then
  # If the IP isn't up yet it will resolve to "" on GCE
  seed_node_ip=""
  while [ "${seed_node_ip}" == "" ]; do
    seed_node_ip=`dig +short $seed_node_dns_name`
  done
elif [[ $cloud_type == "azure" ]]; then
  # If the IP isn't up yet it will resolve to 255.255.255.255 on Azure
  seed_node_ip="255.255.255.255"
  while [ "${seed_node_ip}" == "255.255.255.255" ]; do
    seed_node_ip=`dig +short $seed_node_dns_name`
  done
elif [[ $cloud_type == "aws" ]]; then
  # If the IP isn't up yet it will resolve to "" on AWS?
  seed_node_ip=""
  while [ "${seed_node_ip}" == "" ]; do
    seed_node_ip=`dig +short $seed_node_dns_name`
  done
fi

echo "Configuring OpsCenter with the settings:"
echo cloud_type \'$cloud_type\'
echo seed_node_ip \'$seed_node_ip\'

if [[ $cloud_type == "azure" ]]; then
  ./scripts/os/set_tcp_keepalive_time.sh
fi

if [[ $cloud_type == "azure" ]]; then
  opscenter_broadcast_ip=`curl --retry 10 icanhazip.com`
  ./scripts/opscenter/configure_opscenterd_conf.sh $opscenter_broadcast_ip
fi

echo "Starting OpsCenter..."
./scripts/opscenter/start.sh

echo "Waiting for OpsCenter to start..."
sleep 30

#echo "Connecting OpsCenter to the cluster... $seed_node_ip $opscenter_user $opscenter_pw"
echo "Connecting OpsCenter to the cluster... $seed_node_ip"
./scripts/opscenter/manage_existing_cluster.sh "$seed_node_ip" "$opscenter_user" "$opscenter_pw" "$secure_app"

echo "Changing the keyspace from SimpleStrategy to NetworkTopologyStrategy."
./scripts/opscenter/configure_opscenter_keyspace.sh
