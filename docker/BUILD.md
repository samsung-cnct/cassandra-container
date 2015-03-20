# Container Image Build

## Purpose
Instructions on building the Cassandra and Opscenter Docker images for a Docker standalone deployment or Kubernetes deployment.

NOTE: These build instructions are for building from an OS-X machine.  They should work for any Linux setup, just omit any boot2docker items.

## Prerequisites
* docker
	* boot2docker up
	* export the vars
	* $(boot2docker shellinit)
* GNU Make
* If building the Java
	* Java JDK
	* Maven

## Build
* set your Docker Image repository name.
	* e.g. for dockerhub account myimage
	
	````
	export DOCKER_REPO=myimage
	````
	
	this will create images such as:
	
	````
	myimage/cassandra_kub:v9
	````

### cassandra
* cd cassnadra
* edit Makefile and update the version number VERSION
* make all - create local image
* make push - push image to image repository
* make clean - clean build artifacts and local image

### opscenter
* cd opscenter
* edit Makefile and update the version number VERSION
* make all - create local image
* make push - push image to image repository
* make clean - clean build artifacts and local image

