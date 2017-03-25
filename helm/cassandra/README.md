# Cassandra Chart

Cassandra Cluster based on the Datastax GKE Scripts

* https://github.com/mikeln/cassandra-container/helm/cassandra

## Chart Details
This chart will do the following:

* Start a Cassandra Cluster of N Cassandra nodes (default 6).
	* Starts a Datastax monitoring agent on each Cassandra node.
	* Creates a Persistent Volume (if enabled).
	* Via Stateful Set.
* Start Opsecenter on port 8888 exposed on an external LoadBalancer.
	* Via Deployment.
* If a secure installation is selected, creates Secret used by all Cassandra nodes and Opscenter.

## Configuration

The following tables lists the configurable parameters of the Cassandra chart and their default values.

### Ports

Port informaation is defined in a way that minimizes duplication within the chart templates.

| Port | Description | Default |
| --- | --- | --- |
| `port8888WebUI` | `port-web-ui` | 8888 |
| `port61620Agent` | `port-agent` | 61620 |
| `port7000Huh` | `port-huh` | 7000 |
| `port7001HuhSSL` | `port-huh-ssl` | 7001 |
| `port7199JMX` | `port-jmx` | 7199 |
| `port9042CQL` | `port-cql` | 9042 |
| `port9160Thrift` | `port-thrift` | 9160 |
| `port61621AgentSSL` | `port-agent-ssl` | 61621 |

### Opscenter Service
| Parameter | Description | Default |
| --- | --- | --- |
| `serviceOpscenter.name` | Opscenter Service Name | `cassandra-opscenter` |
| `serviceOpscenter.type` | Service Connection Type | `LoadBalancer` |
| `serviceOpscenter.ports` | Should Not Change||

### Seed Service
Needed by the Cassandra Stateful Set.  Should not Change.

### Cassandra Service (Temporarily Disabled)
| Parameter | Description | Default |
| --- | --- | --- |
| `serviceCassandra.name` | Cassandra External Access Name | `cassandra-svc` |
| `serviceCassandra.type` | Service Connection Type | `LoadBalancer` |
| `serviceCassandra.ports` | Should Not Change||

### Opscenter

| Parameter | Description | Default | Options |
| --- | --- | --- | --- |
| `opscenter.name` | Pod Base Name | `opscenter` ||
| `opscenter.replicaCount` | Number of replicas | 1 ||
| `opscenter.image` | Docker Image | `opscenter_dse_sec` |  `opscenter_dse` <br> `opscenter_dse_sec` <br> `opscenter_dsc21` <br> `opscenter_dsc21_sec`|
| `opscenter.ports` | Should Not Change |||
| `opscenter.command` | Should Not Change |||

### Cassandra Nodes
| Parameter | Description | Default | Options |
| --- | --- | --- | --- |
| `cassandra.name` | Pod Base Name | `cassandra` ||
| `cassandra.replicaCount` | Number of replicas | 6 | Minimum 3 |
| `cassandra.image` | Docker Image | `cassandra_dse_sec` |`cassandra_dse` <br> `cassandra_dse_sec` <br> `cassndra_dsc21` <br> `cassandra_dsc21_sec`|
| `cassandra.ports` | Should Not Change |||
| `cassandra.command` | Should Not Change |||
| `cassandra.resources` | Resources needed by the pod |||
| `cassandra.preStop.command` | Should Not Change |||
| `cassandra.terminationGracePeriodSeconds` | Wait time before pod is deleted on termination.  This limit is needed to allow the cassandra node to drain correctly before it is fully removed from the cluster. | 60 | 45 seems to be minimum |
| `cassandra.datacenter` | Cassandra Cluster Datacenter Name | `sea-001` ||
| `cassandra.rack` | Cassandra Rack Name | `rack-010` ||
| `cassandra.persistence.enabled` | Enable persistent disk volumes.  Otherwise use in-memory storage | `false` | `true` <br> `false` |
| `cassandra.persistence.storageClase` |  | `standard` | |
| `cassandra.persistence.accessModes` |  | `ReadWriteOnce` |  |
| `cassandra.persistence.size` | Persistent disk volume size | `5Gi` |  |
| `cassandra.storageClass.provisioner` | GCE specific | `kubernetes.io/gce-pd` |  |
| `cassandra.storageClass.parameters.type` | GCE specific | `pd-ssd` |  |
| `cassandra.secret.adminpw` | Replacement Admin Account password<br>Account name `king` | Should be specified on the command line to minimize exposure | Only required for `_sec` images |
| `cassandra.secret.opspw` | Opscenter access account password<br>Account name `opscenter` | Should be specified on the command line to minimize exposure | Only required for `_sec` images|
| `cassandra.secret.workrpw` | First user account password<br>Account name `workr` | Should be specified on the command line to minimize exposure |Only required for `_sec` images |


### Resources
| Parameter | Description | Default |
| --- | --- | --- |
| `resources.limits.cpu` |  | `100m` |
| `resources.limits.memory` |  | `128Mi` |
| `resources.requests.cpu` |  | `100m` |
| `resources.requests.memory` |  | `128Mi` |

### Command Line
The chart should be started with a namespace argument, and specify the password values for the initial required users.

`--namespace=cassadnra`

`--set cassandra.secret.adminpw="bogus1",cassandra.secret.opspw="b2",cassandra.secret.workrpw="zone3a"`
