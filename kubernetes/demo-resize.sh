#!/bin/bash
#
# Script to resize cassandra cluster
# uses jq to eval json returns from kubedtl
#
# 5/3/2015 mikeln
#-------
#
VERSION="2.0"
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

# XXX: this won't work if the last component is a symlink
my_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${my_dir}/utils.sh

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
echo "       in the user's PATH or"
echo "       /opt/kubernetes/platforms/darwin/amd64/kubectl"
echo " "
echo "  This script uses jq to parse json.  It must be installed."
echo " "
echo "  And you must have your ~/.kube/config for you cluster set up.  e.g."
echo " "
echo "  local: kubectl config set-cluster local --server=http://172.16.1.102:8080 "
echo "  aws:   kubectl config set-cluster aws --server=http:////52.25.218.223:8080 "
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
# check for required additional BASH app to parse json: 'jq'
#
which jq
if [ $? -ne 0 ];then
        echo "ERROR! jq is not accessible.  Please install it and make sure it is on your PATH"
        exit 8
fi
#
# check to see if kubectl has been configured
#
echo " "
KUBECTL=$(locate_kubectl)
if [ $? -ne 0 ]; then
  exit 1
fi
echo "found kubectl at: ${KUBECTL}"

# XXX: kubectl doesn't seem to provide an out-of-the-box way to ask if a cluster
#      has already been set so we just assume it's already been configured, eg:
#
#      kubectl config set-cluster local --server=http://172.16.1.102:8080 
kubectl_local="${KUBECTL} --cluster=${CLUSTER_LOC}"

CMDTEST=$( $kubectl_local version )
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running?"
    exit 1;
else
    echo "kubectl present: $kubectl_local"
fi
echo " "
# get minion IPs for later...also checks if cluster is up
echo "+++++ finding Kubernetes Nodes services ++++++++++++++++++++++++++++"
NODERET=$($kubectl_local get nodes --output=json  2>/dev/null)
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? (Hint: vagrant status, vagrant up)"
    exit 1;
else
    #
    # TODO: should probably validate that the status id Ready for the minions.  low level concern 
    #
    # parset the json returned
    NODEIPS=$( echo ${NODERET} | jq '.items[].metadata.name' | tr -d "\"" )
    #
    # TODO: may need to eval the return
    #    #
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
            LASTSTATUS_RET=$($kubectl_local get pods --selector=name=cassandra --output=json  2>/dev/null)
            LASTRET=$?
            if [ $? -ne 0 ]; then
                echo -n "Cassandra get pods not problem $REMTIME                                         $CR"
                COMBSTAT=99
                let NUMTRIES=NUMTRIES-1
                sleep 5
            else
                #
                # parse json
                #
                LASTSTATUS=$( echo ${LASTSTATUS_RET} | jq '.items[].status.phase' | tr -d "\"" )
                #
                # TODO: eval for error...
                #
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
