# Cassandra Kubernetes

## Demo 
The demo runs a 2+ node cassandra cluster and a single opscenter node to provide monitoring.  Opscenter should only be used to monitor the cluster in this demo.  Control via Opscenter has not been investigated.

### Scripts
Several bash scripts have been created to automate the creation of the demo.  They automate the sequence documented below.  Note that these scripts assume you are running on a Kraken CoreOS cluster using those IPs and names.

There are 2 scripts: ````demo-run.sh```` and ````demo-down.sh````.  

#### ````demo-run.sh```` 
* Locates the Kubectl needed for Kraken
* Usage:

````
        demo-run.sh [flags]

        Flags:
          -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use
          -h, -?, --help :: print usage
          -v, --version :: print script verion

````

* Uses ~/.kube/config. Requires an entry exists for the desired cluster. Example for local:

````
        apiVersion: v1
        clusters:
        - cluster:
            api-version: v1beta3
            server: http://172.16.1.102:8080
          name: local
        contexts: []
        current-context: ""
        kind: Config
        preferences: {}
        users: []

````

* Uses the information to construct the correct ````kubectl```` command.  e.g.:

````
        kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --cluster=local'
````

* Checks if the Opscenter Service running and starts it.
* Checks if the Cassandra Service running and starts it.
* Waits until both services are running.
* Extracts the desired number of cassandra replicas from the  cassandra-controller.yaml
* Checks if the Cassandra Replication Controller is running, and starts it, but alters the number of replicas to 1. (for the cassandra seed)
* Waits until that pod starts. (up to 15 minutes)
* After that cassandra seed pod starts, wait 10 seconds to allow all the comm to settle.
* Check if the total number of cassandra replicas are running, and resizes to the original desired size.
* Waits until all pods are running. (up to 15 minutes)
* Starts the Opscenter Pod.
* Waits until Opscenter is running (up to 10 minutes)
* Locates the IPs and Ports and provides information to about the connections
* Control-C at any point will terminate and tear down the entire setup (via ````demo-down.sh````)
* Any error will terminate and tear down the entire setup (via ````demo-down.sh````)
* This script can be run multiple times without problems.  I evaluates if every step is already running.  
* Occasionally the cassandra cluster does not see the other nodes.  If this happens run the script again (sometimes it will catch a missing replicated node).  If that does not work, run demo-down.sh and demo-run.sh again.

#### ````demo-down.sh````
* Locates the Kubectl needed for Kraken
* Usage:

````
        demo-down.sh [flags]

        Flags:
          -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use
          -h, -?, --help :: print usage
          -v, --version :: print script verion

````

* Locates the .kubeconfig in the kraken/kubernetes directory
* Uses the information to construct the correct ````kubectl```` command.  e.g.:

````
        kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --cluster=local'
````

* Removes all services
* Resizes the Cassandra RC to Zero
* Removes the Cassandra RC and Opscenter Pods

#### ````demo-resize.sh````
* Locates the Kubectl needed for Kraken
* Usage:

````
        demo-resize.sh [flags]

        Flags:
          -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use
          -s, --size :required: new node size
          -h, -?, --help :: print usage
          -v, --version :: print script verion

````

* Locates the .kubeconfig in the kraken/kubernetes directory
* Uses the information to construct the correct ````kubectl```` command.  e.g.:

````
        kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --cluster=local'
````

* Resizes the Cassandra RC to given --size value


### Sequence
**NOTE: The following shows the default Kubernetes Fedora Cluster, not our Kraken CoreOS Cluster**

* Start your kubernetes cluster [ `vagrant up` or `./cluster/kube-up.sh` ]
* Note the Node (minion) IPs [ `kub get minions` ]
````
      l2067532491-mn:kubernetes mikel_nelson$ kub get minions
      current-context: "vagrant"
      Running: /Users/mikel_nelson/dev/cloud/kubernetes/binary/kubernetes/cluster/../cluster/vagrant/../../platforms/darwin/amd64/kubectl --kubeconfig=/Users/mikel_nelson/.kubernetes_vagrant_kubeconfig get minions
      NAME                LABELS              STATUS
      10.245.1.3          <none>              Ready
      10.245.1.4          <none>              Ready
````
* Edit cassandra-opscenter-service.yaml and replace the publicIPs with the ones from your cluster 
````
      cassandra-opscenter-service.yaml
        id: cassandra-opscenter
        kind: Service
        apiVersion: v1beta1
        port: 8888
        containerPort: 8888
        publicIPs: [ 10.245.1.3, 10.245.1.4 ]
        selector:
           name: opscenter
````
* kub create -f cassandra-opscenter-service.yaml
* kub create -f cassandra-service.yaml
* edit cassandra-controller.yaml and set the number of replicas you want
* kub create -f cassandra-controller.yaml
* wait until all the pods are running
* kub create -f opscenter.yaml
* wait until opscenter is running
* (painful part of the process here) determine the node IP where the opscenter pod is running.
````
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
````
* Use that IP in the following: `http://<IP>:8888`  you should get the opscenter webpage. [ `http://10.245.1.4:8888` ]
* Connect to cluster: `Manage Existing Cluster`. You'll need the Pod IP of one of the cassandra pods [`10.246.1.6`]
* If you were successful...you will see the cassandra nodes.  It can take a while for all the nodes to show up fully. Give it time.
* You should NOT have to "Install Agent", or even be given that choice. 


### Debug
* kub describe pods <pod ID or name>
* kub log <pod ID or name>
* vagrant ssh minion-<x>
	* sudo docker ps
	* sudo docker logs <container>
	* sudo docker exec -it <running container> bash
		* examine stuff... like /var/logs
	* remove image if new one with no version change!
		* sudo docker rmi -f <blah/conatiner:vX> (make sure any pods have been deleted first)
		
		
## Build
See [BUILD](./BUILD.md)

