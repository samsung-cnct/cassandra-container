#!/usr/bin/env bash

echo "Starting DataStax Community"
sudo service cassandra start

echo "Starting the DataStax Agent"
sudo service datastax-agent start
