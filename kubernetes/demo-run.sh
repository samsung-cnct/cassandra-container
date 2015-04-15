#!/bin/bash 
#
# Script to start all the pieces of the cassandra cluster demo with opscenter
#
#
echo " "
echo "=================================================="
echo "   Attempting to Start the"
echo "   Cassandra/Opscenter Kubernetes Demo"
echo "=================================================="
echo "  !!! NOTE  !!!"
echo "  This script uses our kraken project assumptions:"
echo "     kubectl will be located at (for OS-X):"
echo "       /opt/kubernetes/platforms/darwin/amd64/kubectl"
echo "    .kubeconfig is from our kraken project"
echo "=================================================="
#----------------------
# start the services first...this is so the ENV vars are available to the pods
#----------------------
#
# check to see if kubectl has been configured
#
echo " "
echo "Locating kubectl and .kubeconfig..."
DEVBASE=${PWD%/cassandra-container/kubernetes}
echo "DEVBASE ${DEVBASE}"
#
# locate projects...
#
KRAKENDIR=`find ${DEVBASE} -type d -name "kraken" -print | egrep '.*'`
if [ $? -ne 0 ];then
    echo "Could not find the Kraken project."
    exit 1
else
    echo "found: $KRAKENDIR"
fi
KUBECONFIG=`find ${KRAKENDIR} -type f -name ".kubeconfig" -print | egrep 'kubernetes'`
if [ $? -ne 0 ];then
    echo "Could not find Kraken .kubeconfig"
else
    echo "found: $KUBECONFIG"
fi

KUBECTL=`find /opt/kubernetes/platforms/darwin/amd64 -type f -name "kubectl" -print | egrep '.*'`
if [ $? -ne 0 ];then
    echo "Could not find kubectl."
    exit 1
else
    echo "found: $KUBECTL"
fi

#kubectl_local="/opt/kubernetes/platforms/darwin/amd64/kubectl --kubeconfig=/Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig"
kubectl_local="${KUBECTL} --kubeconfig=${KUBECONFIG}"

CMDTEST=`$kubectl_local version`   
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Please make sure it is in your path or you have created an alias"
    exit 1;
else
    echo "kubectl present: $kubectl_local"
fi
echo " "
echo "+++++ starting cassandra services ++++++++++++++++++++++++++++"
$kubectl_local create -f  cassandra-opscenter-service.yaml
if [ $? -ne 0 ]; then
    echo "Opscenter service start error"
else
    echo "Opscenter service started"
fi
$kubectl_local create -f cassandra-service.yaml
if [ $? -ne 0 ]; then
    echo "Cassandra service start error"
else
    echo "Cassandra service started"
fi
echo " "
echo "Services List:"
$kubectl_local get services
echo " "
echo "+++++ starting cassandra pods ++++++++++++++++++++++++++++"
$kubectl_local create -f cassandra-controller.yaml
if [ $? -ne 0 ]; then
    echo "Cassandra replication controller error"
else
    echo "Cassandra replication controller and pod started"
fi
echo " "
echo "Replication Controllers:"
$kubectl_local get rc
echo " "
$kubectl_local create -f opscenter.yaml
if [ $? -ne 0 ]; then
    echo "Opscenter pod error"
else
    echo "Opscenter pod started"
fi
echo " "
echo "Pods:"
$kubectl_local get pods
echo " "
echo "+++++ cassandra started in Kubernetes ++++++++++++++++++++++++++++"
