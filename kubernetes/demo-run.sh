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
#
# setup trap for script signals
#
trap "echo ' ';echo ' ';echo 'SIGNAL CAUGHT, SCRIPT TERMINATING, cleaning up'; . ./demo-down.sh; exit 9 " SIGHUP SIGINT SIGTERM
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
    # clean up the potential mess
    . ./demo-down.sh
    exit 2
else
    echo "Opscenter service started"
fi
$kubectl_local create -f cassandra-service.yaml
if [ $? -ne 0 ]; then
    echo "Cassandra service start error"
    . ./demo-down.sh
    # clean up the potential mess
    exit 2
else
    echo "Cassandra service started"
fi
echo " "
echo "Services List:"
$kubectl_local get services
echo " "
#
# wait until services are ready
#
NUMTRIES=4
LASTRET=1
while [ $LASTRET -ne 0 ] && [ $NUMTRIES -ne 0 ]; do
    $kubectl_local get services cassandra 2>/dev/null
    LASTRET=$?
    if [ $LASTRET -ne 0 ]; then
        echo "Cassandra service not found $NUMTRIES"
        let NUMTRIES=NUMTRIES-1
        sleep 1
    else
        echo "Cassandra service found"
    fi
done
if [ $NUMTRIES -le 0 ]; then
    echo "Cassandra Service did not start in alotted time...exiting"
    # clean up the potential mess
    . ./demo-down.sh
    exit 2
fi

NUMTRIES=4
LASTRET=1
while [ $LASTRET -ne 0 ] && [ $NUMTRIES -ne 0 ]; do
    $kubectl_local get services cassandra-opscenter 2>/dev/null
    LASTRET=$?
    if [ $? -ne 0 ]; then
        echo "Opscenter service not found $NUMTRIES"
        let NUMTRIES=NUMTRIES-1
        sleep 1
    else
        echo "Opscenter service found"
    fi
done
if [ $NUMTRIES -le 0 ]; then
    echo "Opscenter Service did not start in alotted time...exiting"
    # clean up the potential mess
    . ./demo-down.sh
    exit 2
fi
#
# need to wait until these are both found
#
echo " "
echo "+++++ starting cassandra pods ++++++++++++++++++++++++++++"
$kubectl_local create -f cassandra-controller.yaml
if [ $? -ne 0 ]; then
    echo "Cassandra replication controller error"
    . ./demo-down.sh
    # clean up the potential mess
    exit 3
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
    . ./demo-down.sh
    # clean up the potential mess
    exit 3
else
    echo "Opscenter pod started"
fi
echo " "
echo "Pods:"
$kubectl_local get pods
#
# wait for pods start
#
NUMTRIES=96
LASTRET=1
LASTSTATUS="unknown"
while [ $NUMTRIES -ne 0 ] && [ "$LASTSTATUS" != "Running" ]; do
    LASTSTATUS=`$kubectl_local get pods opscenter --output=template --template={{.currentState.status}} 2>/dev/null`
    LASTRET=$?
    if [ $? -ne 0 ]; then
        echo "Opscenter pod not found $NUMTRIES"
        LASTSTATUS="unknown"
        let NUMTRIES=NUMTRIES-1
        sleep 5
    else
        echo "Opscenter pod found $LASTSTATUS"
        if [ "$LASTSTATUS" != "Running" ]; then
            echo "Opscenter pod NOT running $NUMTRIES"
            let NUMTRIES=NUMTRIES-1
            sleep 5
        else
            echo "Opscenter pod running!"
        fi
    fi
done
if [ $NUMTRIES -le 0 ]; then
    echo "Opscenter pod did not start in alotted time...exiting"
    # clean up the potential mess
    . ./demo-down.sh
    exit 3
fi
echo " "
#
# loop over all cassandra instances until running!
#
NUMTRIES=192
LASTRET=1
LASTSTATUS="unknown"
COMBSTAT=99
CRLF=$'\n'
while [ $NUMTRIES -ne 0 ] && [ $COMBSTAT -ne 0 ]; do
    LASTSTATUS=`$kubectl_local get pods --selector=name=cassandra --output=template --template="{{range $.items}}{{.currentState.status}}${CRLF}{{end}}" 2>/dev/null`
    LASTRET=$?
    if [ $? -ne 0 ]; then
        echo "Cassandra get pods not problem $NUMTRIES"
        COMBSTAT=99
        let NUMTRIES=NUMTRIES-1
        sleep 5
    else
        echo "Cassandra get pods found - evaluate statuses -----"
        #
        # pre set the default
        COMBSTAT=0
        for STATE in $LASTSTATUS; do
            echo $STATE
            # only takes one not running
            if [ "$STATE" != "Running" ]; then
                let COMBSTAT=COMBSTAT+1
            fi
        done
        if [ $COMBSTAT -ne 0 ]; then
            echo "$COMBSTAT Cassandra pods are NOT running $NUMTRIES"
            let NUMTRIES=NUMTRIES-1
            sleep 5
        else
            echo "Cassandra pods are running!"
        fi
    fi
done
if [ $NUMTRIES -le 0 ]; then
    echo "Cassandra pods did not start in alotted time...exiting"
    # clean up the potential mess
    . ./demo-down.sh
    exit 4
fi
echo " "
echo "Pods:"
$kubectl_local get pods
echo " "
#
# git the user the correct URLs for opscenter and connecting that to the cluster
#
# NOTE: get services with the template appears to send out on stderr instead of stdout....ugg
#
SERVICEIP=`$kubectl_local get services cassandra-opscenter --output=template --template="{{.portalIP}}:{{.port}}" 2>/dev/null`
PUBLICIP=`$kubectl_local get services cassandra-opscenter --output=template --template="{{.publicIPs}}:{{.port}}" 2>/dev/null`
PODIPS=`$kubectl_local get pods --selector=name=cassandra --output=template --template="{{range $.items}}{{.currentState.podIP}}, {{end}}" 2>/dev/null`

echo "===================================================================="
echo " "
echo "  Cassandra Demo Cluster with Opscenter is Up!"
echo " "
echo "  Opscenter should be accessible via a web browser at this IP:Port"
echo " "
echo "      ${SERVICEIP}"
echo " "
echo " However! There have been issues on certain platforms with the"
echo " service IP given.  If you have issues with that, then you may"
echo " alternatively use one of the minion node public IPs listed:"
echo " "
echo "      ${PUBLICIP}"
echo " "
echo " Once you have the opscenter UI up, you may \"Add An Existing Cluster\""
echo " supplying one of the cassandra POD IPs from the following list:"
echo " "
echo "      ${PODIPS}"
echo " "
echo " You should not try to control the cluster from the UI, just monitor."
echo " "
echo " Please run ./demo-down.sh to stop and remove the demo when you"
echo " are finished."
echo " "
echo "===================================================================="
echo "+++++ cassandra started in Kubernetes ++++++++++++++++++++++++++++"
