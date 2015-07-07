#!/bin/bash

# Setup Cassandra
CONFIG=/etc/cassandra/
IP=${LISTEN_ADDRESS:-`hostname --ip-address`}
#perl -pi -e "s/%%ip%%/$(hostname -I)/g" /etc/cassandra/cassandra.yaml
perl -pi -e "s/%%ip%%/$IP/g" $CONFIG/cassandra.yaml
#
# seems to be root:root at this point..needs to be cassandra:cassandra
#
chown cassandra:cassandra $CONFIG/cassandra.yaml

#
# set config file for agent
#
DCONFIG=/var/lib/datastax-agent/conf
# Start Monitor Agent
#-------------------------------------
# set stomp address if possible...
# 
# Use the endpoint query, which should always be current vs looking for env vars set.
# e.g.  this is deprectaed here:
#STOMP=`env | grep OPSCENTER_PORT_61620_TCP_ADDR | sed 's/OPSCENTER_PORT_61620_TCP_ADDR=//g' | sed -e :a -e N -e 's/\n/,/' -e ta`
#
# Get the kubernetes-ro http ip:port
# query for opscenter endpoint to see if it is already running
# set the stomp address is it is running
#
# Note: we need a good json parser (in bash)...install it here at run (vs in the image...for now).
which jq
if [ $? -ne 0 ]; then
    echo "WARNING jq not accessble,  Unable to set stomp address without a json parser"
else
    #
    # opscenter POD ... MUST be named opscenter
    #
    #KUBSSL="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1beta3/namespaces/default/endpoints/opscenter"
    # 
    # Use DNS instead.  Do NOT include domain as it may be different from system to system
    #
    KUBSSL="https://kubernetes.default/api/v1beta3/namespaces/default/endpoints/opscenter"
    OPSRET=$(curl -s -L --insecure ${KUBSSL})
    if [ $? -ne 0 ];then
        echo "ERROR with ${KUBSSL}.  Stomp address not set"
    else
        #
        # parse for enpoint address...use first one (there should NEVER be more than one..but...)
        #
        STOMPIP=$( echo ${OPSRET} | jq '.subsets[0].addresses[0].IP' | tr -d '"' )
        if [ -z $STOMPIP ] || [ $STOMPIP == "null" ]; then
            echo "WARN No Opscenter IP found: ${STOMPIP}"
        else
            echo "INFO STOMP IP Found: ${STOMPIP}"
            echo "stomp_interface: $STOMPIP" | sudo tee -a $DCONFIG/address.yaml
        fi
    fi
fi
#
# set the rest of the information
#
echo "local_interface: $IP" | sudo tee -a $DCONFIG/address.yaml
echo "agent_rpc_interface: $IP" | sudo tee -a $DCONFIG/address.yaml
echo "jmx_host: $IP" | sudo tee -a $DCONFIG/address.yaml
echo "hosts: [ $IP ]" | sudo tee -a $DCONFIG/address.yaml
#
# seems to be root:root at this point..needs to be cassandra:cassandra
#
chown cassandra:cassandra $DCONFIG/address.yaml
#
# HACK HACK for kubernetes volumes.  createa a root:root (and may be shared), so no way to chown it.
# attempt this here, but not good in the long run
#
chown cassandra:cassandra /cassandra_data
#
# for custom kubernetes seed 
#
export CLASSPATH=/kubernetes-cassandra.jar

#
# debug env for kub...in case of sudden death
#
env | sort
#
ls -l /

echo "Starting Datastax Agent... stomp: $STOMPIP"
sudo service datastax-agent start

# Start Cassandra
# NOTE: this will hang in the foreground (-f) so the container does not go away...
echo Starting Cassandra...
cassandra -f -p /var/run/cassandra.pid
# just to lock up the container in case of a cassandra error
tail -f /var/log/lastlog
