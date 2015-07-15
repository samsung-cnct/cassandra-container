#!/bin/bash  
#
# Script to label for nuc demo
#
# 6/25/2015 mikeln
#-------
#
VERSION="NUC AWS DEMO 2.0"
function usage
{
    echo "Labels Kubernetes Nodes"
    echo ""
    echo "Usage:"
    echo "   demo-run.sh [flags]" 
    echo ""
    echo "Flags:"
    echo "  -h, -?, --help :: print usage"
    echo "  -v, --version :: print script verion"
    echo "  --aws :: label cluster with AWS in the mix"
    echo ""
}
function version
{
    echo "nuc-label.sh version $VERSION"
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
echo "   Attempting to do the"
echo "   Nuc Labelling"
echo "   version: $VERSION"
echo "=================================================="
echo "  !!! NOTE  !!!"
echo "  This script uses our kraken project assumptions:"
echo "     kubectl will be located at (for OS-X):"
echo "       in the user's PATH or at"
echo "       /opt/kubernetes/platforms/darwin/amd64/kubectl"
echo " "
echo "  Also, your Kraken Kubernetes Cluster Must be"
echo "  up and Running.  "
echo " "
echo "  And you must have your ~/.kube/config for you cluster set up.  e.g."
echo " "
echo "  local: kubectl config set-cluster local --server=http://172.16.1.102:8080 "
echo "  aws:   kubectl config set-cluster aws --server=http:////52.25.218.223:8080 "
echo "  nuc:   kubectl config set-cluster nuc --server=http:////172.16.16.15:8080 "
echo "=================================================="
#----------------------
# start the services first...this is so the ENV vars are available to the pods
#----------------------
#
# process args
#
# DEMO>>>>> default for this is nuc
#
CLUSTER_LOC="nuc"
AWS_LABLE="NO"
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
        --aws )
            AWS_LABEL="YES"
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
echo "Using Kubernetes cluster: $CLUSTER_LOC AWS in the mix: $AWS_LABEL"
#
# setup trap for script signals
#
trap "echo ' ';echo ' ';echo 'SIGNAL CAUGHT, SCRIPT TERMINATING, no clean up'; exit 9 " SIGHUP SIGINT SIGTERM
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

echo "Local cmd: ${kubectl_local}"
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
echo "======== labeling nodes ====================================="
# ignore any errors.. label with work if not already there, and error if already there.
#
# DEMO>>>>>>>>>> fixed labelling!!!d
#
#  172.16.16.16 opscenter
#
#  172.16.16.40-49 cassandra
#
#OLABEL="type=uinode"
OLABEL="region=zone1"
OPSCENTER_NODE="172.16.16.16"
echo "Labelling: $OPSCENTER_NODE with $OLABEL"
$kubectl_local label nodes --overwrite $OPSCENTER_NODE $OLABEL

#CLABEL="type=cassandra"
CLABEL="region=zone2"
CASSANADRA_NODES=("172.16.16.40" "172.16.16.41" "172.16.16.42" "172.16.16.43" "172.16.16.44" "172.16.16.45" "172.16.16.46" "172.16.16.47" "172.16.16.48" "172.16.16.49" )
for CNODE in ${CASSANADRA_NODES[@]}; do
  echo "Labelling $CNODE with $CLABEL"
  $kubectl_local label nodes --overwrite $CNODE $CLABEL
done

TLABEL="region=zone3"
REGION_NODES=("172.16.16.50" "172.16.16.51" "172.16.16.52" "172.16.16.53" "172.16.16.54" "172.16.16.55" "172.16.16.56" "172.16.16.57" "172.16.16.58" "172.16.16.59" )

AWS_NODES=("10.1.101.50" "10.1.101.51" "10.1.101.52" "10.1.101.53" "10.1.101.54" )

if [ "$AWS_LABEL" == "YES" ];then
   # if aws then all nucs are region 2
   for TNODE in ${REGION_NODES[@]}; do
      echo "Labelling $TNODE with $CLABEL"
      $kubectl_local label nodes --overwrite $TNODE $CLABEL
   done

   for ANODE in ${AWS_NODES[@]}; do
     echo "Labelling $ANODE with $TLABEL"
     $kubectl_local label nodes --overwrite $ANODE $TLABEL
   done
else
   for TNODE in ${REGION_NODES[@]}; do
      echo "Labelling $TNODE with $TLABEL"
      $kubectl_local label nodes --overwrite $TNODE $TLABEL
   done
fi

echo " "
$kubectl_local get nodes 

