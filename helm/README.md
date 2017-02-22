# Helm Version of Cassandra Setup

## Purpose
This directory contains versions of Datastax Cassandra that runs with "more" current version of kubernetes, and deployed via Helm.

### Relevance
#### 2/22/2017 MLN Added

## Directories

### cassandra
This Helm chart deploys a pre-built cassandra image (see **image** directory).  It uses statefulset, secrets, persistent storage.

### image
This directory contains the items needed to build the different versions of the Datastax cassandra and opscenter. (DSC - community, DSE - enterprise)
Currently stored into `quay.io/mikeln`

### cassandra-script
This Helm chart deploys a cassandra cluster using the datastax scripts to build the Pod images at runtime (vs pre-built above).  It uses statefulset, secrets, persistent storage.

This uses forks of repos: `<>/google-container-engine-dse/`  and `<>/install-datastax-ubuntu/`


