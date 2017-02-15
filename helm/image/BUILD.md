# Container Image Build

## Purpose
Instructions on building the Cassandra and Opscenter Agent Docker images for a Kubernetes deployment.

NOTE: These build instructions are for building from an OS-X machine.  They should work for any Linux setup.

## Prerequisites
* docker = boot2docker, docker-machine, or more current docker
* GNU Make

## Build
* set your Docker Image repository name.
	* e.g. for dockerhub account myimage
	
	````
	export DOCKER_REPO=quay.io/myrepo
	````
	
	this will create images such as:
	
	````
	quay.io/myrepo/cassandra_dsc21:v1.0.0
	````

### cassandra, opscenter
* edit Makefile and update the version number VERSION
	* DSC_IMG_VERSION := v1.0.3
	* DSE_IMG_VERSION := v1.0.11
* make all - create all images locally
* make push - push images to image repository
* make clean - clean build artifacts and local image

### Dockerfile Images
* Dockerfile.dsc-dsc - cassandra_dsc21
* Dockerfile.dsc-ops - opscenter_dsc21
* Dockerfile.dsc-dsc-sec - cassandra_dsc21_sec
* Dockerfile.dsc-ops-sec - opscenter_dsc21_sec
* Dockerfile.dse-dse - cassandra_dse
* Dockerfile.dse-ops - opscenter_dse
* Dockerfile.dse-dse-sec - cassandra_dse_sec
* Dockerfile.dse-ops-sec - opscenter_dse_sec

### Make Targets
* all: build-dsc build-dse build-dsc-sec build-dse-sec
* push: push-dsc push-dse push-dsc-sec push-dse-sec
* clean: clean-dsc clean-dse clean-dsc-sec clean-dse-sec





