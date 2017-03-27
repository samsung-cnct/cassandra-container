This builds cassandra and opscenter images based on the datastax scripts.

1/2017 mikeln

See the [BUILD.md](./BUILD.md) for build instructions.


### Images

* cassandra_dsc21, opscenter_dsc21 - Datastax Community Edition
* cassandra_dse, opscenter_dse - Datastax Enterprise Edition
* cassandra_dsc21_sec, opscenter_dsc21_sec - Datastax Community with security enabled
* cassandra_dse_sec, opscenter_dse_sec - Datastax Enterprise with security enabled

### Image Start Scripts
The scripts are modified from the Datastax gke scripts here:

* `git@github.com:DSPN/google-container-engine-dse.git`
* `git@github.com:DSPN/install-datastax-ubuntu.git`


3/14/2017 - Still TBD running this on AWS 

### Run

These should be run via the **Helm** script.   (see the **Helm** directory)

The passwords must be passed in on the command line.  These arguments are currenty required for both secure and non-secure runs.   The passwords are not set in the non-secure runs, the default cassandra admin password is valid in that case.

Required arguments (via `--set`):

* `cassandra.secret.adminpw="bogus1"` - password for the cassandra admin - `king`
* `cassandra.secret.opspw="another2"` - password for the opscenter user - `opscenter`
* `cassandra.secret.workrpw="zone3"` - password for the first regular user - `workr`

The Namespace should also be set via the `--namespace=` argument.


#### Example

```
helm install --namespace=cassandra --debug --set cassandra.secret.adminpw="bogus1",cassandra.secret.opspw="another2",cassandra.secret.workrpw="zone3"  ./
```











