#!/bin/bash 
#
# Script to stop all the pieces of the cassandra cluster demo with opscenter
#
#-------
# some best practice stuff
unset CDPATH
#
echo " "
echo "=================================================="
echo "   Attempting to Stop and Delete the"
echo "   Cassandra/Opscenter Kubernetes Demo"
echo "=================================================="
#----------------------
# start the services first...this is so the ENV vars are available to the pods
#----------------------
#
# check to see if kubectl has be configured
#
echo " "
echo "Locating kubectl and .kubeconfig..."
SCRIPTPATH="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
cd ${SCRIPTPATH}
DEVBASE=${SCRIPTPATH%/cassandra-container/kubernetes}
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
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? (Hint: vagrant status, vagrant up)"
    exit 1;
else
    echo "kubectl present: $kubectl_local"
fi
echo " "
echo "+++++ stopping cassandra services ++++++++++++++++++++++++++++"
$kubectl_local delete services opscenter 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Opscenter service already down"
else
    echo "Opscenter service deleted"
fi
$kubectl_local delete services cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Cassandra service already down"
else
    echo "Cassandra service deleted"
fi
echo " "
echo "Remaining Services List:"
$kubectl_local get services
echo " "
echo "+++++ stopping cassandra pods ++++++++++++++++++++++++++++"
$kubectl_local resize --replicas=0 rc cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Cassandra pods already down"
else
    echo "Cassandra pods deleted"
fi
$kubectl_local delete rc cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Cassandra Replication Controller already down"
else
    echo "Cassandra Replication Controller deleted"
fi
echo " "
echo "Remaining Replication Controllers:"
$kubectl_local get rc
echo " "
$kubectl_local delete pods opscenter 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Opscenter pods already down"
else
    echo "Opscenter pods deleted"
fi
echo " "
echo "Remaining Pods:"
$kubectl_local get pods
echo " "
echo "+++++ cassandra stopped and deleted from Kubernetes ++++++++++++++++++++++++++++"
