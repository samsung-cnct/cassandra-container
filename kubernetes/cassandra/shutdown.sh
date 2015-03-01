echo "Stopping Cassandra..."
sudo kill `cat /var/run/cassandra.pid`

echo "Stopping Agent..."
sudo service datastax-agent stop
