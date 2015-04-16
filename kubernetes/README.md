# Cassandra Kubernetes

## Demo 
The demo runs a 2+ node cassandra cluster and a single opscenter node to provide monitoring.  Opscenter should only be used to monitor the cluster in this demo.  Control via Opscenter has not been investigated.

### Scripts
Several bash scripts have been created to automate the creation of the demo.  They automate the sequence documented below.  Note that these scripts assume you are running on a Kraken CoreOS cluster using those IPs and names.

There are 2 scripts: ````demo-run.sh```` and ````demo-down.sh````.  

#### ````demo-run.sh```` 
* Locates the Kubectl needed for Kraken
* Locates the .kubeconfig in the kraken/kubernetes directory
* Uses the information to construct the correct ````kubectl```` command.  e.g.:

      kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --kubeconfig='\''/Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig'\'''

* Starts the Opscenter and Cassandra services and waits until they are running
* Starts the Opscenter Pod and the Cassandra Replication Controller
* Waits until Opscenter is running (up to 10 minutes)
* Waits until all the Cassandra Pods are running (up to 15 minutes after Opscenter)
* Locates the IPs and Ports and provides information to about the connections
* Control-C at any point will terminate and tear down the entire setup (via ````demo-down.sh````)
* Any error will terminate and tear down the entire setup (via ````demo-down.sh````)

#### ````demo-down.sh````
* Locates the Kubectl needed for Kraken
* Locates the .kubeconfig in the kraken/kubernetes directory
* Uses the information to construct the correct ````kubectl```` command.  e.g.:

      kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --kubeconfig='\''/Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig'\'''

* Removes all services
* Resizes the Cassandra RC to Zero
* Removes the Cassandra RC and Opscenter Pods

#### Example Run
* Start the Kraken CoreOS Cluster

      l2067532491-mn:kubernetes mikel_nelson$ alias kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --kubeconfig='\''/Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig'\'''
      l2067532491-mn:kubernetes mikel_nelson$ pwd
       /Users/mikel_nelson/dev/cloud/kraken/kubernetes
      l2067532491-mn:kubernetes mikel_nelson$ vagrant up
       Bringing machine 'etcd-node' up with 'virtualbox' provider...
       Bringing machine 'master-node' up with 'virtualbox' provider...
       Bringing machine 'minion-01' up with 'virtualbox' provider...
       Bringing machine 'minion-02' up with 'virtualbox' provider...
       ==> etcd-node: Importing base box 'coreos-alpha'...
           :
           Lots more stuff here
           :
       ==> minion-02: Running triggers after up...
       ==> minion-02: making sure ssh agent has the default vagrant key...
       Identity added: /Users/mikel_nelson/.vagrant.d/insecure_private_key (/Users/mikel_nelson/.vagrant.d/insecure_private_key)
      l2067532491-mn:kubernetes mikel_nelson$ kub get minions
       F0416 15:48:43.430323   10086 get.go:70] Client error: Get http://172.16.1.102:8080/api/v1beta1/minions: dial tcp 172.16.1.102:8080: connection refused
            
            wait until minions are up
            
      l2067532491-mn:kubernetes mikel_nelson$ vagrant status
       Current machine states:

       etcd-node                 running (virtualbox)
       master-node               running (virtualbox)
       minion-01                 running (virtualbox)
       minion-02                 running (virtualbox)

       This environment represents multiple VMs. The VMs are all listed
       above with their current state. For more information about a specific
       VM, run `vagrant status NAME`.
      l2067532491-mn:kubernetes mikel_nelson$ kub get minions
       NAME           LABELS    STATUS
       172.16.1.103   <none>    Ready
       172.16.1.104   <none>    Ready
           
* Execute ````demo-run.sh````

      l2067532491-mn:kubernetes mikel_nelson$ ./demo-run.sh

       ==================================================
          Attempting to Start the
          Cassandra/Opscenter Kubernetes Demo
       ==================================================
          !!! NOTE  !!!
          This script uses our kraken project assumptions:
             kubectl will be located at (for OS-X):
                /opt/kubernetes/platforms/darwin/amd64/kubectl
             .kubeconfig is from our kraken project

          Also, your Kraken Kubernetes Cluster Must be
          up and Running.
       ==================================================

       Locating Kraken Project kubectl and .kubeconfig...
       DEVBASE /Users/mikel_nelson/dev/cloud
       found: /Users/mikel_nelson/dev/cloud/kraken
       found: /Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig
       found: /opt/kubernetes/platforms/darwin/amd64/kubectl
       kubectl present: /opt/kubernetes/platforms/darwin/amd64/kubectl --kubeconfig=/Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig

       +++++ starting cassandra services ++++++++++++++++++++++++++++
       services/cassandra-opscenter
       Opscenter service started
       services/cassandra
       Cassandra service started

       Services List:
       NAME                  LABELS                                    SELECTOR         IP                     PORT
       cassandra             <none>                                    name=cassandra   10.100.28.42    9042
       cassandra-opscenter   <none>                                    name=opscenter   10.100.69.247   8888
       kubernetes            component=apiserver,provider=kubernetes   <none>           10.100.0.2      443
       kubernetes-ro         component=apiserver,provider=kubernetes   <none>           10.100.0.1      80

       NAME        LABELS    SELECTOR         IP             PORT
       cassandra   <none>    name=cassandra   10.100.28.42   9042
       Cassandra service found
       NAME                  LABELS    SELECTOR         IP              PORT
       cassandra-opscenter   <none>    name=opscenter   10.100.69.247   8888
       Opscenter service found

       +++++ starting cassandra pods ++++++++++++++++++++++++++++
       replicationControllers/cassandra
       Cassandra replication controller and pod started

       Replication Controllers:
       CONTROLLER   CONTAINER(S)   IMAGE(S)                      SELECTOR         REPLICAS
       cassandra    cassandra      mikeln/cassandra_kub_mln:v9   name=cassandra   2

       pods/opscenter
       Opscenter pod started

       Pods:
       POD               IP        CONTAINER(S)   IMAGE(S)                      HOST            LABELS           STATUS    CREATED
       cassandra-qvwq6             cassandra      mikeln/cassandra_kub_mln:v9   <unassigned>    name=cassandra   Pending   Less than a second
       cassandra-w3mpc             cassandra      mikeln/cassandra_kub_mln:v9   172.16.1.104/   name=cassandra   Pending   Less than a second
       opscenter                   opscenter      mikeln/opscenter-kub-mln:v1   <unassigned>    name=opscenter   Pending   Less than a second
       Opscenter pod: Waiting - NOT running 595 secs remaining...........................................................
       Opscenter pod running!

       2 Cassandra pods NOT running, 0 running. 885 secs remaining
       2 Cassandra pods are running!


       Pods:
       POD               IP            CONTAINER(S)   IMAGE(S)                      HOST                        LABELS           STATUS    CREATED
       cassandra-qvwq6   10.244.58.3   cassandra      mikeln/cassandra_kub_mln:v9   172.16.1.103/172.16.1.103   name=cassandra   Running   11 minutes
       cassandra-w3mpc   10.244.50.3   cassandra      mikeln/cassandra_kub_mln:v9   172.16.1.104/172.16.1.104   name=cassandra   Running   11 minutes
       opscenter         10.244.50.4   opscenter      mikeln/opscenter-kub-mln:v1   172.16.1.104/172.16.1.104   name=opscenter   Running   11 minutes

       ====================================================================

         Cassandra Demo Cluster with Opscenter is Up!

         Opscenter should be accessible via a web browser at this IP:Port

             10.100.69.247:8888

        However! There have been issues on certain platforms with the
        service IP given.  If you have issues with that, then you may
        alternatively use one of the minion node public IPs listed:

             [172.16.1.103 172.16.1.104]:8888

        Once you have the opscenter UI up, you may "Add An Existing Cluster"
        supplying one of the cassandra POD IPs from the following list:

             10.244.58.3, 10.244.50.3,

        You should not try to control the cluster from the UI, just monitor.

        Please run ./demo-down.sh to stop and remove the demo when you
        are finished.

       ====================================================================
       +++++ cassandra started in Kubernetes ++++++++++++++++++++++++++++
       
* Execute ````demo-down.sh````

       l2067532491-mn:kubernetes mikel_nelson$ ./demo-down.sh

      ==================================================
         Attempting to Stop and Delete the
         Cassandra/Opscenter Kubernetes Demo
      ==================================================

      Locating kubectl and .kubeconfig...
      DEVBASE /Users/mikel_nelson/dev/cloud
      found: /Users/mikel_nelson/dev/cloud/kraken
      found: /Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig
      found: /opt/kubernetes/platforms/darwin/amd64/kubectl
      kubectl present: /opt/kubernetes/platforms/darwin/amd64/kubectl --kubeconfig=/Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig

      +++++ stopping cassandra services ++++++++++++++++++++++++++++
      services/cassandra-opscenter
      Opscenter service deleted
      services/cassandra
      Cassandra service deleted

      Remaining Services List:
      NAME            LABELS                                    SELECTOR   IP           PORT
      kubernetes      component=apiserver,provider=kubernetes   <none>     10.100.0.2   443
      kubernetes-ro   component=apiserver,provider=kubernetes   <none>     10.100.0.1   80

      +++++ stopping cassandra pods ++++++++++++++++++++++++++++
      resized
      Cassandra pods deleted
      replicationControllers/cassandra
      Cassandra Replication Controller deleted

      Remaining Replication Controllers:
      CONTROLLER   CONTAINER(S)   IMAGE(S)   SELECTOR   REPLICAS

      pods/opscenter
      Opscenter pods deleted

      Remaining Pods:
      POD       IP        CONTAINER(S)   IMAGE(S)   HOST      LABELS    STATUS    CREATED

      +++++ cassandra stopped and deleted from Kubernetes ++++++++++++++++++++++++++++


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
* kub create -f opscenter.yaml
* kub create -f cassandra-service.yaml
* edit cassandra-controller.yaml and set the number of replicas you want
* kub create -f cassandra-controller.yaml
* wait until all the pods are running
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
* vagrant ssh minion-<x>
	* sudo docker ps
	* sudo docker logs <container>
	* sudo docker exec -it <running container> bash
		* examine stuff... like /var/logs
	* remove image if new one with no version change!
		* sudo docker rmi -f <blah/conatiner:vX> (make sure any pods have been deleted first)
		
		
## Build
See [BUILD](./BUILD.md)

