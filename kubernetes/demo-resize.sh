#!/bin/bash
#
# Script to resize cassandra cluster
#
# 5/3/2015 mikeln
#-------
#
VERSION="1.0"
function usage
{
    echo "Resizes cassandra cluster"
    echo ""
    echo "Usage:"
    echo "   demo-resize.sh [flags]" 
    echo ""
    echo "Flags:"
    echo "  -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use"
    echo "  -s, --size :required: new node size"
    echo "  -h, -?, --help :: print usage"
    echo "  -v, --version :: print script verion"
    echo ""
}
function version
{
    echo "demo-resize.sh version $VERSION"
}
# some best practice stuff
CRLF=$'\n'
CR=$'\r'
unset CDPATH
#
echo " "
echo "=================================================="
echo "   Attempting to resize the"
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
NEW_SIZE=
CLUSTER_LOC="local"
TMP_LOC=$CLUSTER_LOC
while [ "$1" != "" ]; do
    case $1 in
        -c | --cluster )
            shift
            TMP_LOC=$1
            ;;
        -s | --size )
            shift
            NEW_SIZE=$1
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
if [ -z "$NEW_SIZE" ] || [ $NEW_SIZE -lt 0  ];then
    echo ""
    echo "ERROR Invalid size: $NEW_SIZE"
    echo ""
    usage
    exit 1
fi
echo "Resizing Kubernetes cluster: $NEW_SIZE"
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
trap "echo ' ';echo ' ';echo 'SIGNAL CAUGHT, SCRIPT TERMINATING, cleaning up'; exit 9 " SIGHUP SIGINT SIGTERM
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
        #
        # resize up to desired original size
        $kubectl_local resize --replicas=$NEW_SIZE rc cassandra 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Cassandra pods resize up error"
            # clean up the potential mess
            exit 3
        else
            echo "Cassandra pods resized to $NEW_SIZE"
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
            exit 4
        fi

echo "===================================================================="
echo " "
echo "  Cassandra Demo Cluster Resized to $NEW_SIZE!"
echo " "
echo "    $kubectl_local resize --replicas=<N> rc cassandra"
echo " "
echo " where <N> is the number of nodes"
echo " "
echo "===================================================================="
echo "+++++ cassandra resized in Kubernetes ++++++++++++++++++++++++++++"
