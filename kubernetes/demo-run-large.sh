#!/bin/bash
#
# Script to start all the pieces of the cassandra cluster demo with opscenter
# uses jq to eval json returns from kubectl
#
# 4/15/2015 mikeln
#-------
#
VERSION="3.0"
function usage
{
    echo "Runs cassandra cluster and opscenter on large cluster"
    echo ""
    echo "Usage:"
    echo "   demo-run-large.sh [flags]" 
    echo ""
    echo "Flags:"
    echo "  -c, --cluster : large : [large, local, aws, ???] selects the cluster yaml/json to use"
    echo "  -h, -?, --help :: print usage"
    echo "  -v, --version :: print script verion"
    echo ""
}
function version
{
    echo "demo-run-large.sh version $VERSION"
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
echo "   Attempting to Start the"
echo "   Cassandra/Opscenter Kubernetes Demo"
echo "   version: $VERSION"
echo "=================================================="
echo "  !!! NOTE  !!!"
echo "  This script uses our kraken project assumptions:"
echo "     kubectl will be located at (for OS-X):"
echo "       in the user's PATH or at"
echo "       /opt/kubernetes/platforms/darwin/amd64/kubectl"
echo " "
echo "  This script uses jq to parse json.  It must be installed."
echo " "
echo "  Also, your Kraken Kubernetes Cluster Must be"
echo "  up and Running.  "
echo " "
echo "  And you must have your ~/.kube/config for you cluster set up.  e.g."
echo " "
echo "  large:   kubectl config set-cluster large --server=http:////52.25.218.223:8080 "
echo "=================================================="
#----------------------
# start the services first...this is so the ENV vars are available to the pods
#----------------------
#
# process args
#
STARTTIME=0
CURTIME=0
ENDTIME=0
#
CLUSTER_LOC="large"
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

CMDTEST=$($kubectl_local version)
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running?"
    exit 1;
else
    echo "kubectl present: $kubectl_local"
fi
echo " "
# get minion IPs for later...also checks if cluster is up...and if your .kube/config is defined
echo "+++++ finding Kubernetes Nodes services ++++++++++++++++++++++++++++"
NODEIPS=""
FIRSTIP=""
NODERET=$($kubectl_local get nodes --output=json  2>/dev/null)
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? Did you set the correct values in your ~/.kube/config file for ${CLUSTER_LOC}?"
    exit 1;
else
    #
    # TODO: should probably validate that the status id Ready for the minions.  low level concern 
    #
    # parset the json returned
    NODEIPS=$( echo ${NODERET} | jq '.items[].metadata.name' | tr -d "\"" )
    #
    # TODO: may need to eval the return
    #
    echo "Kubernetes minions (nodes) IP(s):"
    for ip in $NODEIPS;do
        echo "   $ip "
        if [ "$FIRSTIP" == "" ]; then
            FIRSTIP=$ip
        fi
    done
fi
echo " "
echo "======== labeling nodes ====================================="
# ignore any errors.. label with work if not already there, and error if already there.
#
# for large aws cluster...look for special node-002 (else node-001)
LABELRET=$( $kubectl_local get nodes --selector="kraken-node=node-002" --output=json 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? Did you set the correct values in your ~/.kube/config file for ${CLUSTER_LOC}?"
    exit 5;
else
    # 
    # parse for name
    UINODE=$( echo ${LABELRET} | jq '.items[].metadata.name' |  tr -d "\"" )
    if [[ -z $UINODE ]]; then
        # get node-001 instead
        #
        LABELRET=$( $kubectl_local get nodes --selector="kraken-node=node-001" --output=json 2>/dev/null)
        # NOTE: not check for error here...
        UINODE=$( echo ${LABELRET} | jq '.items[].metadata.name' |  tr -d "\"" )
    fi
    for k in $UINODE;do
        echo "Labelling: $k"
        LRET=$( $kubectl_local label nodes $k type=uinode  2>/dev/null )
        echo "Label ret: $LRET"
        break
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
# Find controller file for the given env (if possible)
#
CASSANDRA_CONTOLLER_BASE_NAME="cassandra-controller"
CASSANDRA_CONTROLLER_YAML="$CASSANDRA_CONTOLLER_BASE_NAME-$CLUSTER_LOC.yaml"
if [ ! -f "$CASSANDRA_CONTROLLER_YAML" ]; then
    echo "WARNING $CASSANDRA_CONTROLLER_YAML not found.  Using $CASSANDRA_CONTOLLER_BASE_NAME.yaml instead."
    CASSANDRA_CONTROLLER_YAML="$CASSANDRA_CONTOLLER_BASE_NAME.yaml"
fi
#
# get the final number of replicas for later
#
FINAL_SIZE=$(grep "replicas:" $CASSANDRA_CONTROLLER_YAML | cut -d ':' -f2 | tr -d '[[:space:]]')
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
    cat $CASSANDRA_CONTROLLER_YAML | sed 's/replicas:[ 1234567890]*/replicas: 1/' | $kubectl_local create -f -
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
#
# timings
#
STARTTIME=$(date +%s)
#
echo " "
echo "Replication Controllers:"
$kubectl_local get rc
echo " "
#
# see how many are running...if less than desired start the otheres
CUR_SIZE_RET=$($kubectl_local get rc  cassandra --output=json 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error getting number of Cassandra Pods Replicated"
    . ./demo-down.sh --cluster $CLUSTER_LOC
    exit 3
else
    #
    # parse pson return
    #
    CUR_SIZE=$( echo ${CUR_SIZE_RET} | jq '.status.replicas' | tr -d "\"" )
    #
    # TODO: may need to eval for errors
    #
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
            LASTSTATUS_RET=$($kubectl_local get pods --selector=name=cassandra --output=json  2>/dev/null)
            LASTRET=$?
            if [ $? -ne 0 ]; then
                echo -n "Cassandra get seed pods not problem $REMTIME                                         $CR"
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
        #--------------------
        # LARGE cluster...start opscenter here first...before all the other cassandra pods
        #
        # set name based on environment
        #
        OPSCENTER_POD_BASE_NAME="opscenter"
        OPSCENTER_POD_YAML="$OPSCENTER_POD_BASE_NAME-$CLUSTER_LOC.yaml"
        if [ ! -f "$OPSCENTER_POD_YAML" ]; then
            echo "WARNING $OPSCENTER_POD_YAML not found.  Using $OPSCENTER_POD_BASE_NAME.yaml instead."
            OPSCENTER_POD_YAML="$OPSCENTER_POD_BASE_NAME.yaml"
        fi
        #
        $kubectl_local get pods opscenter 2>/dev/null
        if [ $? -ne 0 ];then
            # start a new one
            $kubectl_local create -f $OPSCENTER_POD_YAML
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
        NUMTRIES=5280
        LASTRET=1
        LASTSTATUS="unknown"
        while [ $NUMTRIES -ne 0 ] && [ "$LASTSTATUS" != "Running" ]; do
            let REMTIME=NUMTRIES*5
            LASTSTATUS_RET=$($kubectl_local get pods opscenter --output=json  2>/dev/null)
            LASTRET=$?
            if [ $? -ne 0 ]; then
                echo -n "Opscenter pod not found $REMTIME"
                echo -n "  $CR"
                LASTSTATUS="unknown"
                let NUMTRIES=NUMTRIES-1
                sleep 5
            else
	            #
	            # parse json
	            #
	            LASTSTATUS=$( echo ${LASTSTATUS_RET} | jq '.status.phase' | tr -d "\"" )
	            #
	            # TODO: eval for error...
                #
                #echo "Opscenter pod found $LASTSTATUS"
                if [ "$LASTSTATUS" != "Running" ]; then
                    echo -n "Opscenter pod: $LASTSTATUS - NOT running $REMTIME secs remaining"
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
PUBLICPORT_RET=$($kubectl_local get services opscenter --output=json  2>/dev/null)
PUBLICPORT=$( echo ${PUBLICPORT_RET} | jq '.spec.ports[].nodePort' | tr -d "\"" )
SEEDPODIP_RET=$($kubectl_local get pods --selector=name=cassandra --output=json 2>/dev/null)
SEEDPODIP=$( echo ${SEEDPODIP_RET} | jq '.items[].status.podIP' | tr -d "\"" )
SEEDPODIPS=$(echo $SEEDPODIP | sed 's/,$//' | tr , '\n')
echo "===================================================================="
echo " "
echo "  Opscenter should be accessible via a web browser at one of "
echo "  these IP:Port(s):"
echo " "
echo "      <your domain name>:${PUBLICPORT}"
echo " "
echo " Once you have the opscenter UI up, you may \"Manage An Existing Cluster\""
echo " supplying ONE of the cassandra POD IPs from the following list:"
echo " "
for ip in ${SEEDPODIPS};do
echo "      $ip"
done
echo " "
echo "===================================================================="
        echo " "
        echo "Ramping up cassandro pods to desired size"
        echo " "
        # LARGE 
        #--------------------
        # now ramp up all the instances + opscenter
        #
        #
        # resize up to desired original size
        #$kubectl_local resize --replicas=$FINAL_SIZE rc cassandra 2>/dev/null
        $kubectl_local resize --replicas=$FINAL_SIZE rc cassandra 
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
        NUMTRIES=5280
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
            . ./demo-down.sh --cluster $CLUSTER_LOC
            exit 4
        fi

    else
        echo "All Cassadra Replicas are started"
    fi
fi
echo " "
ENDTIME=$(date +%s)
echo " "
#
# git the user the correct URLs for opscenter and connecting that to the cluster
#
# NO ERROR CHECKING HERE...this is ALL just Informational for the user
#
#
PUBLICIP_RET=$($kubectl_local get services opscenter --output=json  2>/dev/null)
PUBLICIP=$( echo ${PUBLICIP_RET} | jq '.spec.publicIPs' | tr -d "\"" )

# remove [] if present
PUBLICIPS=$(echo $PUBLICIP | tr -d '[]' | tr , '\n')
#
# NEED TO VALIDATE the PUBLICIPS against the NODEIPS
#
VALIDIPS=""
#for ip0 in ${PUBLICIPS};do
    for ip0 in ${NODEIPS};do
#        if [ "$ip0" == "$ip1" ];then
            VALIDIPS=${VALIDIPS}${CRLF}$ip0
            break
#        fi
    done
#done
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
# 
PODIP_RET=$($kubectl_local get pods --selector=name=cassandra --output=json 2>/dev/null)
PODIP=$( echo ${PODIP_RET} | jq '.items[].status.podIP' | tr -d "\"" )
PODIPS=$(echo $PODIP | sed 's/,$//' | tr , '\n')

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
echo "     elapsed run time: $(($ENDTIME - $STARTTIME))  seconds "
echo " "
echo "===================================================================="
echo "+++++ cassandra started in Kubernetes ++++++++++++++++++++++++++++"
