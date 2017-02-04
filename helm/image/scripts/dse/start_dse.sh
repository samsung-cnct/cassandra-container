#!/usr/bin/env bash

echo "Starting DataStax Enterprise"
sudo service dse start
if [[ $? != 0 ]]; then
    echo "Datastax Enterprise not available...attempting Community version instead"
    echo "Starting DataStax Community"
    sudo service cassandra start
fi
