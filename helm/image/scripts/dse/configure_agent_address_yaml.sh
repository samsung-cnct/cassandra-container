#!/usr/bin/env bash

node_ip=${1?"Missing node IP arg 1"}
node_broadcast_ip=${2?"Missing broadcast IP arg 2"}
opscenter_ip=${3?"Missing opscenter IP arg 3"}
# security
cass_user=${4?"Missing user arg 4"}
cass_pass=${5?"Missing user pw arg 5"}
mcass_user=${6?"Missing monitor user arg 6"}
mcass_pass=${7?"Missing monitor pw arg 7"}
#
secure_app=${8:-"yes"}

# looks like the agent creates an empty /var/lib/datastax-agent/conf/address.yaml when it starts for the first time
# given that, we're not going to worry about backing it up

file=/var/lib/datastax-agent/conf/address.yaml

if [ "$secure_app" == "yes" ]; then

cat <</EOF > $file
stomp_interface: $opscenter_ip
agent_rpc_interface: $node_ip
agent_rpc_broadcast_address: $node_broadcast_ip
cassandra_user: $cass_user
cassandra_pass: $cass_pass
monitored_cassandra_user: $mcass_user
monitored_cassandra_pass: $mcass_pass
/EOF

else

cat <</EOF > $file
stomp_interface: $opscenter_ip
agent_rpc_interface: $node_ip
agent_rpc_broadcast_address: $node_broadcast_ip
/EOF

fi

chown cassandra $file
chgrp cassandra $file
