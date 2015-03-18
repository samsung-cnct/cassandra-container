# Cassandra Kubernetes

This is the same setup but adapted for kubernetes

### Sequence
* Start you kubernetes cluster [ `vagrant up` or `./cluster/kube-up.sh` ]
* Note the Node (minion) IPs [ `kub get minions` ]

      l2067532491-mn:kubernetes mikel_nelson$ kub get minions
      current-context: "vagrant"
      Running: /Users/mikel_nelson/dev/cloud/kubernetes/binary/kubernetes/cluster/../cluster/vagrant/../../platforms/darwin/amd64/kubectl --kubeconfig=/Users/mikel_nelson/.kubernetes_vagrant_kubeconfig get minions
      NAME                LABELS              STATUS
      10.245.1.3          <none>              Ready
      10.245.1.4          <none>              Ready

* Edit cassandra-opscenter-service.yaml and replace the publicIPs with the ones from your cluster 

      cassandra-opscenter-service.yaml
        id: cassandra-opscenter
        kind: Service
        apiVersion: v1beta1
        port: 8888
        containerPort: 8888
        publicIPs: [ 10.245.1.3, 10.245.1.4 ]
        selector:
           name: opscenter

* kub create -f cassandra-opscenter-service.yaml
* kub create -f opscenter.yaml
* kub create -f cassandra-service.yaml
* edit cassandra-controller.yaml and set the number of replicas you want
* kub create -f cassandra-controller.yaml
* wait until all the pods are running
* (painful part of the process here) determine the node IP where the opscenter pod is running.

      l2067532491-mn:kubernetes mikel_nelson$ kub get pods
      current-context: "vagrant"
      Running: /Users/mikel_nelson/dev/cloud/kubernetes/binary/kubernetes/cluster/../cluster/vagrant/../../platforms/darwin/amd64/kubectl --kubeconfig=/Users/mikel_nelson/.kubernetes_vagrant_kubeconfig get pods
      POD                 IP                  CONTAINER(S)        IMAGE(S)                           HOST                    LABELS              STATUS
      cassandra-hh2gd     10.246.1.6          cassandra           mikeln/cassandra_kub_mln:v8        10.245.1.3/10.245.1.3   name=cassandra      Running
      cassandra-nyxxv     10.246.2.6          cassandra           mikeln/cassandra_kub_mln:v8        10.245.1.4/10.245.1.4   name=cassandra      Running
      opscenter           10.246.2.7          opscenter           mikeln/opscenter-kub-mln:v1        10.245.1.4/10.245.1.4   name=opscenter      Running
      skydns-fplln        10.246.1.2          etcd                quay.io/coreos/etcd:latest         10.245.1.3/10.245.1.3   k8s-app=skydns      Running
                                          kube2sky            kubernetes/kube2sky:1.0
                                          skydns              kubernetes/skydns:2014-12-23-001

* Use that IP in the following: `http://<IP>:8888`  you should get the opscenter webpage. [ `http://10.245.1.4:8888` ]
* Connect to cluster: `Manage Existing Cluster`. You'll need the Pod IP of one of the cassandra pods [`10.246.1.6`]
* If you were successful...you will see the cassandra nodes.  It can take a while for all the nodes to show up fully. Give it time.
* You should NOT have to "Install Agent", or even be given that choice. (NOTE: looks like the STOMP may have to be set...)

### Issues
* stomp address setup - not sure if opscenter-service IP will work
* some port statuses per node are not registering.

### Debug
* kub describe pods <pod ID or name>
* vagrant ssh minion-<x>
	* sudo docker ps
	* sudo docker logs <container>
	* sudo docker exec -it <running container> bash
		* examine stuff... like /var/logs
	* remove image if new one with no version change!
		* sudo docker rmi -f <blah/conatiner:vX> (make sure any pods have been deleted first)
		
		
