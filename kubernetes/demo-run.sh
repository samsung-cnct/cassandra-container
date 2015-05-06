#!/bin/bash
#
# Script to start all the pieces of the cassandra cluster demo with opscenter
#
# 4/15/2015 mikeln
#-------
#
VERSION="1.0"
function usage
{
    echo "Runs cassandra cluster and opscenter"
    echo ""
    echo "Usage:"
    echo "   demo-run.sh [flags]" 
    echo ""
    echo "Flags:"
    echo "  -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use"
    echo "  -h, -?, --help :: print usage"
    echo "  -v, --version :: print script verion"
    echo ""
}
function version
{
    echo "demo-run.sh version $VERSION"
}
# some best practice stuff
CRLF=$'\n'
CR=$'\r'
unset CDPATH
#
echo " "
echo "=================================================="
echo "   Attempting to Start the"
echo "   Cassandra/Opscenter Kubernetes Demo"
echo "   version: $VERSION"
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
#----------------------
# start the services first...this is so the ENV vars are available to the pods
#----------------------
#
# process args
#
CLUSTER_LOC="local"
TMP_LOC=$CLUSTER_LOC
while [ "$1" != "" ]; do
    case $1 in
        -c | --cluster )
            shift
            TMP_LOC=$1
            ;;
        -v | --version )
            version
            exit
            ;;
        -h | -? | --help )
            usage
            exit
            ;;
         * ) 
             usage
             exit 1
    esac
    shift
done
if [ -z "$TMP_LOC" ];then
    echo ""
    echo "ERROR No Cluster Supplied."
    echo ""
    usage
    exit 1
else
    CLUSTER_LOC=$TMP_LOC
fi
echo "Using Kubernetes cluster: $CLUSTER_LOC"
#
# setup trap for script signals
#
trap "echo ' ';echo ' ';echo 'SIGNAL CAUGHT, SCRIPT TERMINATING, cleaning up'; . ./demo-down.sh --cluster $CLUSTER_LOC; exit 9 " SIGHUP SIGINT SIGTERM
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
KUBECONFIG=`find ${KRAKENDIR}/kubernetes/${CLUSTER_LOC} -type f -name ".kubeconfig" -print | egrep '.*'`
if [ $? -ne 0 ];then
    echo "Could not find ${KRAKENDIR}/kubernetes/${CLUSTER_LOC}/.kubeconfig"
    exit 1
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
NODEIPS=`$kubectl_local get nodes --output=template --template="{{range $.items}}{{.metadata.name}}${CRLF}{{end}}" 2>/dev/null`
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
$kubectl_local get services cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    #
    #  Use cluster arg to find the desired yaml
    #       e.g.  <blah>-aws.yaml, <blah>-local.yaml 
    #             or <blah>.yaml if local and local isn't present
    #
    CASS_SERVICE_BASE_NAME="cassandra-service"
    CASS_SERVICE_YAML="$CASS_SERVICE_BASE_NAME-$CLUSTER_LOC.yaml"
    if [ ! -f "$CASS_SERVICE_YAML" ]; then
        echo "WARNING $CASS_SERVICE_YAML not found.  Using $CASS_SERVICE_BASE_NAME.yaml instead."
        CASS_SERVICE_YAML="$CASS_SERVICE_BASE_NAME.yaml"
    fi
    #$kubectl_local create -f cassandra-service.yaml
    $kubectl_local create -f $CASS_SERVICE_YAML
    if [ $? -ne 0 ]; then
        echo "Cassandra service start error"
        . ./demo-down.sh --cluster $CLUSTER_LOC
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
            . . 2
        fi
    fi
else
    echo "Cassandra service already running...skipping"
fi

$kubectl_local get services opscenter 2>/dev/null
if [ $? -ne 0 ]; then
    #
    # use cluster arg to find the desired yaml
    #       e.g.  <blah>-aws.yaml, <blah>-local.yaml 
    #             or <blah>.yaml if local and local isn't present
    #
    OPS_SERVICE_BASE_NAME="opscenter-service"
    OPS_SERVICE_YAML="$OPS_SERVICE_BASE_NAME-$CLUSTER_LOC.yaml"
    if [ ! -f "$OPS_SERVICE_YAML" ]; then
        echo "WARNING $OPS_SERVICE_YAML not found.  Using $OPS_SERVICE_BASE_NAME.yaml instead."
        OPS_SERVICE_YAML="$OPS_SERVICE_BASE_NAME.yaml"
    fi
    #$kubectl_local create -f  opscenter-service.yaml
    $kubectl_local create -f $OPS_SERVICE_YAML
    if [ $? -ne 0 ]; then
        echo "Opscenter service start error"
        # clean up the potential mess
        . ./demo-down.sh --cluster $CLUSTER_LOC
        exit 2
    else
        echo "Opscenter service started"
        #
        # wait until services are ready
        #
        NUMTRIES=4
        LASTRET=1
        while [ $LASTRET -ne 0 ] && [ $NUMTRIES -ne 0 ]; do
            $kubectl_local get services opscenter 2>/dev/null
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
            . ./demo-down.sh --cluster $CLUSTER_LOC
            exit 2
        fi
    fi
else
    echo "Opscenter service already running...skipping"
fi
echo ""

echo " "
echo "Services List:"
$kubectl_local get services
echo " "
echo "+++++ starting cassandra pods ++++++++++++++++++++++++++++"
#
# check if things are already running..and skip
#
# get the final number of replicas for later
#
FINAL_SIZE=`grep "replicas:" cassandra-controller.yaml | cut -d ':' -f2 | tr -d '[[:space:]]'`
#
# pipe the file in, so we can replace the replicas: xx with replicas: 1.
# This does 2 things:
#     1) Starts a single copy of cassandra.  It will make itself the seed
#     2) Does not alter the original file in any way
#
$kubectl_local get rc cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    #
    # start a new one
    #
    # NOTE: timing issue... need to "ramp up" size:
    #       let 1 start, then resize to desired
    #       specification.
    #
    # First pull the desired size out of the yaml
    # Then change that to 1.
    # Wait for pod startup.
    # Then resize to pulled value
    #
    # pipe the file in, so we can replace the replicas: xx with replicas: 1.
    # This does 2 things:
    #     1) Starts a single copy of cassandra.  It will make itself the seed
    #     2) Does not alter the original file in any way
    #
    #$kubectl_local create -f cassandra-controller.yaml
    cat cassandra-controller.yaml | sed 's/replicas:[ 1234567890]*/replicas: 1/' | $kubectl_local create -f -
    # TODO: this error may be bogus..
    if [ $? -ne 0 ]; then
        echo "Cassandra replication controller error"
        . ./demo-down.sh --cluster $CLUSTER_LOC
        # clean up the potential mess
        exit 3
    else
        echo "Cassandra replication controller and seed pod started"
    fi
else
    echo "Cassandra replication controller already running...skipping"
fi
echo " "
echo "Replication Controllers:"
$kubectl_local get rc
echo " "
#
# see how many are running...if less than desired start the otheres
CUR_SIZE=`$kubectl_local get rc  cassandra --output=template --template="{{$.status.replicas}}" 2>/dev/null`
if [ $? -ne 0 ]; then
    echo "Error getting number of Cassandra Pods Replicated"
    . ./demo-down.sh --cluster $CLUSTER_LOC
    exit 3
else
    echo "Current cassandra initial nodes: $CUR_SIZE final wanted: $FINAL_SIZE"
    if [ $CUR_SIZE -lt $FINAL_SIZE ]; then
        # start the others
        #
        # Need to wait for the first one to start running before we ramp up all instancdes
        #
        # allow 15 minutes for these to come up (180*5=900 sec)
        NUMTRIES=180
        LASTRET=1
        LASTSTATUS="unknown"
        COMBSTAT=99
        RUNSTAT=0
        while [ $NUMTRIES -ne 0 ] && [ $COMBSTAT -ne 0 ]; do
            let REMTIME=NUMTRIES*5
            LASTSTATUS=`$kubectl_local get pods --selector=name=cassandra --output=template --template="{{range $.items}}{{.status.phase}}${CRLF}{{end}}" 2>/dev/null`
            LASTRET=$?
            if [ $? -ne 0 ]; then
                echo -n "Cassandra get seed pods not problem $REMTIME                                         $CR"
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
                    echo -n "$COMBSTAT Cassandra seed pods NOT running, $RUNSTAT running. $REMTIME secs remaining  $CR"
                    let NUMTRIES=NUMTRIES-1
                    sleep 5
                else
                    echo ""
                    echo "$RUNSTAT Cassandra seed pods are running!"
                fi
            fi
        done
        echo ""
        if [ $NUMTRIES -le 0 ]; then
            echo "Cassandra seed pods did not start in alotted time...exiting"
            # clean up the potential mess
            . ./demo-down.sh --cluster $CLUSTER_LOC
            exit 4
        fi
        echo "Pods:"
        $kubectl_local get pods
        echo ""
        #
        # add a slight delay...let seed pod settle
        #
        echo "Waiting 10 seconds to let the seed node settle"
        sleep 10
        #
        # now ramp up all the instances + opscenter
        #
        #
        # resize up to desired original size
        $kubectl_local resize --replicas=$FINAL_SIZE rc cassandra 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Cassandra pods resize up error"
            . ./demo-down.sh --cluster $CLUSTER_LOC
            # clean up the potential mess
            exit 3
        else
            echo "Cassandra pods resized to $FINAL_SIZE"
        fi
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
            LASTSTATUS=`$kubectl_local get pods --selector=name=cassandra --output=template --template="{{range $.items}}{{.status.phase}}${CRLF}{{end}}" 2>/dev/null`
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
            . ./demo-down.sh --cluster $CLUSTER_LOC
            exit 4
        fi

    else
        echo "All Cassadra Replicas are started"
    fi
fi
echo " "
#
$kubectl_local get pods opscenter 2>/dev/null
if [ $? -ne 0 ];then
    # start a new one
    $kubectl_local create -f opscenter.yaml
    if [ $? -ne 0 ]; then
        echo "Opscenter pod error"
        . ./demo-down.sh --cluster $CLUSTER_LOC
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
    LASTSTATUS=`$kubectl_local get pods opscenter --output=template --template={{.status.phase}} 2>/dev/null`
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
    . ./demo-down.sh --cluster $CLUSTER_LOC
    exit 3
fi
echo " "
echo " "
#
# git the user the correct URLs for opscenter and connecting that to the cluster
#
# NO ERROR CHECKING HERE...this is ALL just Informational for the user
#
#v1beta3
SERVICEIP=`$kubectl_local get services opscenter --output=template --template="{{.spec.portalIP}}" 2>/dev/null`
#SERVICEIP=`$kubectl_local get services opscenter --output=template --template="{{.portalIP}}:{{.port}}" 2>/dev/null`
#v1beta3
PUBLICPORT=`$kubectl_local get services opscenter --output=template --template="{{range $.spec.ports}}{{.port}}${CRLF}{{end}}" 2>/dev/null`
#PUBLICPORT=`$kubectl_local get services opscenter --output=template --template="{{.port}}" 2>/dev/null`
#v1beta3
PUBLICIP=`$kubectl_local get services opscenter --output=template --template="{{.spec.publicIPs}}" 2>/dev/null`
#PUBLICIP=`$kubectl_local get services opscenter --output=template --template="{{.publicIPs}}" 2>/dev/null`
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
    echo "Please correct your opscenter-service.yaml file publicIPs: entry to include"
    echo "at least one of the Node IPs lists above"
    echo ""
    echo "Leaving demo up.  You may tear id down via ./demo-down.sh --cluster $CLUSTER_LOC"
    echo "======!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!=================="
#    exit 99
fi

# remove trailing comma
# v1beta3
PODIP=`$kubectl_local get pods --selector=name=cassandra --output=template --template="{{range $.items}}{{.status.podIP}}, {{end}}" 2>/dev/null`
#PODIP=`$kubectl_local get pods --selector=name=cassandra --output=template --template="{{range $.items}}{{.currentState.podIP}}, {{end}}" 2>/dev/null`
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
echo " Please run ./demo-down.sh --cluster $CLUSTER_LOC to stop and remove the demo when you"
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
