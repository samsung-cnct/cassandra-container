# Cassandra Kubernetes

This is the same setup but adapted for kubernetes

### Sequence
* Start you kubernetes cluster
* Note the Node (minion) IPs
* Edit cassandra-opscenter-service.yaml and replace the publicIPs with the ones from your cluster
* kub create -f cassandra-opscenter-service.yaml
* kub create -f opscenter.yaml
* kub create -f cassandra-service.yaml
* edit cassandra-controller.yaml and set the number of replicas you want
* kub create -f cassandra-controller.yaml
* wait until all the pods are running
* (painful part of the process here) determine the node IP where the opscenter pod is running.
* Use that IP in the following: http://<IP>:8888  you should get the opscenter webpage
* Connect to cluster:  you'll need the Pod IP of one of the cassandra pods. 
* If you were successful...you will see the cassandra nodes.  It can take a while for all the nodes to show up fully. Give it time.
* You should NOT have to "Install Agent", or even be given that choice. (NOTE: looks like the STOMP may have to be set...)

### Issues
* stomp address setup - not sure if opscenter-service IP will work
* some port statuses per node are not registering.

