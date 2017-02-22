#!/usr/bin/env bash
#
# This script performs items necessary before a node is removed
#
NODETOOL_CMD=$(which nodetool)
if [ $? -ne 0 ];then
    echo "ERROR - could not find nodetool"
    exit 3
fi

echo "Node: Found nodetool at $NODETOOL_CMD"
$NODETOOL_CMD status
if [ $? -ne 0 ];then
    echo "ERROR - could not nodetool status"
    exit 4
fi

#---------------------------------------------
#
#  If node is up: nodetool decommision
#  when node is doesn: nodetool removenode
#
#----------
#  nodetool status (to get status of this node...issue is not local node by default)...try nodetool netstats instead.
#  nodetool netstats  - local node by default.  Look for Mode: 
#          JOINING - issue decommission (?)
#          LEAVING - currently in decommission - wait for DECOMMISSIONED
#          NORMAL - issue decommission
#          DECOMMISSIONED - issude removenode
#          CLIENT - ??? just removenode (with no decommission first?)
#
#echo "Node: Getting status for current node"
#
#retval=$($NODETOOL_CMD netstats)
#if [ $? -ne 0 ];then
#    echo "ERROR - could not local nodetool netstats - will just attempt to removenode"
#    # TODO: removenode
#fi
##TODO: eval
#echo "Initial: $retval"

#echo ""
#echo ""
echo "Node: Decommissioning Node"
$NODETOOL_CMD decommission
if [ $? -ne 0 ];then
    echo "ERROR - could not nodetool decommission the local node"
fi

# wait a bit... 
#sleep 30
#
#retval=$($NODETOOL_CMD netstats)
#if [ $? -ne 0 ];then
#    echo "ERROR - could not local nodetool netstats - will just attempt to removenode"
#    # TODO: removenode
#fi
#TODO: eval
#echo "After 30 sec: $retval"
#
#echo ""
#echo ""
#echo "Node: Removing Node"
#$NODETOOL_CMD removenode
#if [ $? -ne 0 ];then
#    echo "ERROR - could not nodetool removenode the local node"
#    # try to force it
#    $NODETOOL_CMD removenode force
#fi
#TODO: should attempt to force if an issue
echo "Node: Done with node"
exit 0
