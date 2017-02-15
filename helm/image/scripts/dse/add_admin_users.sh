#!/usr/bin/env bash
#
# Lock down admin users
#  - disable the default cassandra user
#  - create users for admin, opscenter, workr
#  - use passwords supplied 
#
admin_user=${1?"Missing admin id arg 1"}
admin_pw=${2?"Missing admin pw arg 2"}
opscenter_user=${3?"Missing opscenter id arg 3"}
opscenter_pw=${4?"Missing opscenter pw arg 4"}
workr_user=${5?"Missing workr id arg 5"}
workr_pw=${6?"Missing workr pw arg 6"}

CQLSH_CMD=$(which cqlsh)
if [ $? -ne 0 ];then
    echo "ERROR - could not find cqlsh"
    exit 1
fi

echo "Found cqlsh at $CQLSH_CMD"

#
NODETOOL_CMD=$(which nodetool)
if [ $? -ne 0 ];then
    echo "ERROR - could not find nodetool"
    exit 1
fi

#
# use this to wait for cluster
#
# allow 60 sec 30*2sec retries
RETRIES=30
echo "Found nodetool at $NODETOOL_CMD"
$NODETOOL_CMD status
while [ $? -ne 0 ];do
    RETRIES=$((RETRIES-1))
    if [ $RETRIES -gt 0 ];then
      echo "ERROR - could not nodetool status $RETRIES ...waiting"
      sleep 2
      $NODETOOL_CMD status
    else
      echo "ERROR - could not nodetool status after many retries"
      exit 2
    fi
done

#---------------------------------------------
# determine if these changes have already occured...each node will attempt.   Check for ability to login via default superuser.  If that fails check for new superuser.  IF that fails...then we have a problem.
# allos 2 min 24*5sec of retries
RETRIES=24
echo "Checking if user updates have been performed."
$CQLSH_CMD -u cassandra -p cassandra -e "list users;"
#if [ $? -ne 0 ];then
while [ $? -ne 0 ];do
    echo "WARN: Check $RETRIES for user update.  May have been done by another node already.  This is OK."
    $CQLSH_CMD -u $admin_user -p $admin_pw -e "list users;"
    if [ $? -ne 0 ];then
        echo "ERROR: Check $RETRIES for user update.  Can not access with either superuser."
        RETRIES=$((RETRIES-1))
        if [ $RETRIES -gt 0 ];then
           sleep 5
           $CQLSH_CMD -u cassandra -p cassandra -e "list users;"
       else
           echo "ERROR: Repairing Node."
           $NODETOOL_CMD cleanup 
           if [ $? -ne 0 ];then
              echo "ERROR - could not nodetool repair this node"
           fi
           exit 2
       fi
    else
       echo "Changes appear to be already performed.  Running node repair."
       $NODETOOL_CMD repair 
       if [ $? -ne 0 ];then
           echo "WARN - could not nodetool repair this node"
       fi
       exit 0
       break
    fi
done
#fi
#---------------------------------------------
# alter keyspace system_auth with replication = { 'class' : 'NetworkTopologyStrategy', 'dc0' : 3 }
# recommended by Datastax docs.
#
echo "Altering Replication"
$CQLSH_CMD -u cassandra -p cassandra -e "alter keyspace system_auth with replication = { 'class' : 'NetworkTopologyStrategy', 'dc0' : 3 };"
if [ $? -ne 0 ];then
    echo "ERROR: Unable to alter replication"
    exit 2
fi
#
# Need to "repair" all the nodes to propogate the replication. (???)
#
#======== new admin and disable old =================
# 
# create user king with password 'royal' superuser;
echo "Changing Admin"
$CQLSH_CMD -u cassandra -p cassandra -e "create user $admin_user with password '$admin_pw' superuser;"
if [ $? -ne 0 ];then
    echo "ERROR: Unable to create new superuser"
    exit 3
fi
echo "Added user $admin_user"
# 
# alter user cassandra with password 'randomcrap093284059507!!!' nosupseruser;
# 
echo "Disable Default Admin"
GEN_PW=$(cat /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
$CQLSH_CMD -u $admin_user -p $admin_pw -e "alter user cassandra with password '$GEN_PW' nosuperuser;"
if [ $? -ne 0 ];then
    echo "ERROR: Unable to alter default superuser"
    exit 3
fi
# 
# create user opscenter with password 'view0psCenter!!';
echo "Creating opscenter user"
$CQLSH_CMD -u $admin_user -p $admin_pw -e "create user $opscenter_user with password '$opscenter_pw';"
if [ $? -ne 0 ];then
    echo "ERROR: Unable to create new opscenter user"
    exit 3
fi
echo "Added user $opscenter_user"
# 
# create user workr with password 'letM3see!?';
echo "Creating workr user"
$CQLSH_CMD -u $admin_user -p $admin_pw -e "create user $workr_user with password '$workr_pw';"
if [ $? -ne 0 ];then
    echo "ERROR: Unable to create new workr user"
    exit 3
fi
#
# list users;
#
$CQLSH_CMD -u $admin_user -p $admin_pw -e "list users;"
if [ $? -ne 0 ];then
    echo "ERROR: Unable to list users"
    exit 3
fi
#
# NOTE: have to create the keyspace first BEFORE we can give rights to it...
#       ASSUME the opscenter keyspace is "OpsCenter"  (with the quotes)
#
$CQLSH_CMD -u $admin_user -p $admin_pw -e "create keyspace if not exists \"OpsCenter\" with replication = { 'class' : 'NetworkTopologyStrategy', 'dc0' : 2 };"
if [ $? -ne 0 ];then
    echo "ERROR: Unable to create new OpsCenter keyspace"
    exit 3
fi
echo "Added keyspace OpsCenter"
#
#grant all on keyspace "OpsCenter" to opscenter;
#echo "granting opscenter"
$CQLSH_CMD -u $admin_user -p $admin_pw -e "grant all on keyspace \"OpsCenter\" to $opscenter_user;"
if [ $? -ne 0 ];then
    echo "ERROR: Unable to set opscenter permissions"
    exit 3
fi
# grant all on keyspace workr to workr;
#echo "granting workr"
#$CQLSH_CMD -u $admin_user -p $admin_pw -e "grant all on keyspace workr to $workr_user;"
#if [ $? -ne 0 ];then
#    echo "ERROR: Unable to set workr permissions"
#    exit 3
#fi
#
# do recomended procedure (node repair) after any cahnges of this sort.
#$NODETOOL_CMD repair -local
#if [ $? -ne 0 ];then
#   echo "ERROR - could not nodetool repair -local this node"
#fi
exit 0
