#!/bin/bash 
#
# Script to start all the pieces of the cassandra cluster demo with opscenter
#
# 4/15/2015 mikeln
#-------
# some best practice stuff
CRLF=$'\n'
CR=$'\r'
unset CDPATH
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
echo " "
echo "  Also, your Kraken Kubernetes Cluster Must be"
echo "  up and Running.  "
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
echo "Locating Kraken Project kubectl and .kubeconfig..."
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
# get minion IPs for later...also checks if cluster is up
echo "+++++ finding Kubernetes Nodes services ++++++++++++++++++++++++++++"
NODEIPS=`$kubectl_local get minions --output=template --template="{{range $.items}}{{.hostIP}}${CRLF}{{end}}" 2>/dev/null`
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? (Hint: vagrant status, vagrant up)"
    exit 1;
else
    #
    # TODO: should probably validate that the status id Ready for the minions.  low level concern 
    #
    echo "Kubernetes minions (nodes) IP(s):"
    for ip in $NODEIPS;do
        echo "   $ip "
    done
fi
echo " "
echo "+++++ starting cassandra services ++++++++++++++++++++++++++++"
#
# check to see if the services are already running...don't start if so
#
$kubectl_local get services cassandra-opscenter 2>/dev/null
if [ $? -ne 0 ]; then
    $kubectl_local create -f  cassandra-opscenter-service.yaml
    if [ $? -ne 0 ]; then
        echo "Opscenter service start error"
        # clean up the potential mess
        . ./demo-down.sh
        exit 2
    else
        echo "Opscenter service started"
        #
        # wait until services are ready
        #
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
    fi
else
    echo "Opscenter service already running...skipping"
fi
echo ""

$kubectl_local get services cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    $kubectl_local create -f cassandra-service.yaml
    if [ $? -ne 0 ]; then
        echo "Cassandra service start error"
        . ./demo-down.sh
        # clean up the potential mess
        exit 2
    else
        echo "Cassandra service started"
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
    fi
else
    echo "Cassandra service already running...skipping"
fi

echo " "
echo "Services List:"
$kubectl_local get services
echo " "
echo "+++++ starting cassandra pods ++++++++++++++++++++++++++++"
#
# check if things are already running..and skip
#
$kubectl_local get rc cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    # start a new one
    $kubectl_local create -f cassandra-controller.yaml
    if [ $? -ne 0 ]; then
        echo "Cassandra replication controller error"
        . ./demo-down.sh
        # clean up the potential mess
        exit 3
    else
        echo "Cassandra replication controller and pod started"
    fi
else
    echo "Cassandra replication controller already running...skipping"
fi
echo " "
echo "Replication Controllers:"
$kubectl_local get rc
echo " "

$kubectl_local get pods opscenter 2>/dev/null
if [ $? -ne 0 ];then
    # start a new one
    $kubectl_local create -f opscenter.yaml
    if [ $? -ne 0 ]; then
        echo "Opscenter pod error"
        . ./demo-down.sh
        # clean up the potential mess
        exit 3
    else
        echo "Opscenter pod started"
    fi
else
    echo "Opscenter pod is already present...skipping"
fi
echo " "
echo "Pods:"
$kubectl_local get pods
echo ""
echo "Waiting for all needed pods to indicate Running"
echo ""
#
# wait for pods start
#
# allow 10 minutes for these to come up (120*5=600 sec)
NUMTRIES=120
LASTRET=1
LASTSTATUS="unknown"
while [ $NUMTRIES -ne 0 ] && [ "$LASTSTATUS" != "Running" ]; do
    let REMTIME=NUMTRIES*5
    LASTSTATUS=`$kubectl_local get pods opscenter --output=template --template={{.currentState.status}} 2>/dev/null`
    LASTRET=$?
    if [ $? -ne 0 ]; then
        echo -n "Opscenter pod not found $REMTIME"
        D=$NUMTRIES
        while [ $D -ne 0 ]; do
            echo -n "."
            let D=D-1
        done
        echo -n "  $CR"
        LASTSTATUS="unknown"
        let NUMTRIES=NUMTRIES-1
        sleep 5
    else
        #echo "Opscenter pod found $LASTSTATUS"
        if [ "$LASTSTATUS" != "Running" ]; then
            echo -n "Opscenter pod: $LASTSTATUS - NOT running $REMTIME secs remaining"
            let D=NUMTRIES/2
            while [ $D -ne 0 ]; do
                echo -n "."
                let D=D-1
            done
            echo -n "  $CR"
            let NUMTRIES=NUMTRIES-1
            sleep 5
        else
            echo ""
            echo "Opscenter pod running!"
        fi
    fi
done
echo ""
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
#
# allow 15 minutes for these to come up (180*5=900 sec)
NUMTRIES=180
LASTRET=1
LASTSTATUS="unknown"
COMBSTAT=99
RUNSTAT=0
while [ $NUMTRIES -ne 0 ] && [ $COMBSTAT -ne 0 ]; do
    let REMTIME=NUMTRIES*5
    LASTSTATUS=`$kubectl_local get pods --selector=name=cassandra --output=template --template="{{range $.items}}{{.currentState.status}}${CRLF}{{end}}" 2>/dev/null`
    LASTRET=$?
    if [ $? -ne 0 ]; then
        echo -n "Cassandra get pods not problem $REMTIME                                         $CR"
        COMBSTAT=99
        let NUMTRIES=NUMTRIES-1
        sleep 5
    else
        #echo "Cassandra get pods found - evaluate statuses -----"
        #
        # pre set the default
        COMBSTAT=0
        RUNSTAT=0
        for STATE in $LASTSTATUS; do
            #echo $STATE
            # only takes one not running
            if [ "$STATE" != "Running" ]; then
                let COMBSTAT=COMBSTAT+1
            else
                let RUNSTAT=RUNSTAT+1
            fi
        done
        if [ $COMBSTAT -ne 0 ]; then
            echo -n "$COMBSTAT Cassandra pods NOT running, $RUNSTAT running. $REMTIME secs remaining  $CR"
            let NUMTRIES=NUMTRIES-1
            sleep 5
        else
            echo ""
            echo "$RUNSTAT Cassandra pods are running!"
        fi
    fi
done
echo ""
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
# NO ERROR CHECKING HERE...this is ALL just Informational for the user
#
SERVICEIP=`$kubectl_local get services cassandra-opscenter --output=template --template="{{.portalIP}}:{{.port}}" 2>/dev/null`
PUBLICPORT=`$kubectl_local get services cassandra-opscenter --output=template --template="{{.port}}" 2>/dev/null`
PUBLICIP=`$kubectl_local get services cassandra-opscenter --output=template --template="{{.publicIPs}}" 2>/dev/null`
# remove [] if present
PUBLICIPS=`echo $PUBLICIP | tr -d '[]' | tr , '\n'`
#
# NEED TO VALIDATE the PUBLICIPS against the NODEIPS
#
VALIDIPS=""
for ip0 in ${PUBLICIPS};do
    for ip1 in ${NODEIPS};do
        if [ "$ip0" == "$ip1" ];then
            VALIDIPS=${VALIDIPS}${CRLF}$ip0
            break
        fi
    done
done
#
# check to see that we acutally HAVE a publicly accessible IP
#
if [ -z "$VALIDIPS" ];then
    echo "======!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!=================="
    echo ""
    echo "No valid publicIPs have been defined that match a node IP.  The web UI will not be accessible."
    echo "Opscenter publicIPs:"
    echo "${PUBLICIPS}"
    echo "Node IPs:"
    echo "${NODEIPS}"
    echo ""
    echo "Please correct your cassandra-opscenter-service.yaml file publicIPs: entry to include"
    echo "at least one of the Node IPs lists above"
    echo ""
    echo "Leaving demo up.  You may tear id down via ./demo-down.sh"
    echo "======!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!=================="
    exit 99
fi

# remove trailing comma
PODIP=`$kubectl_local get pods --selector=name=cassandra --output=template --template="{{range $.items}}{{.currentState.podIP}}, {{end}}" 2>/dev/null`
PODIPS=`echo $PODIP | sed 's/,$//' | tr , '\n'`

echo "===================================================================="
echo " "
echo "  Cassandra Demo Cluster with Opscenter is Up!"
echo " "
echo "  Opscenter should be accessible via a web browser at one of "
echo "  these IP:Port(s):"
echo " "
for ip in ${VALIDIPS};do
echo "      $ip:${PUBLICPORT}"
done
echo " "
echo " Once you have the opscenter UI up, you may \"Manage An Existing Cluster\""
echo " supplying ONE of the cassandra POD IPs from the following list:"
echo " "
for ip in ${PODIPS};do
echo "      $ip"
done
echo " "
echo " You should not try to control the cluster from the UI, just monitor."
echo " "
echo " Please run ./demo-down.sh to stop and remove the demo when you"
echo " are finished."
echo " "
echo " To change the number of cassandra nodes, use the kubectl resize command:"
echo " "
echo "    $kubectl_local resize --replicas=<N> rc cassandra"
echo " "
echo " where <N> is the number of nodes"
echo " "
echo "===================================================================="
echo "+++++ cassandra started in Kubernetes ++++++++++++++++++++++++++++"
