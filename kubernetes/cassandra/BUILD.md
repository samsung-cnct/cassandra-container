# Container Image Build

## Purpose
Instructions on building the Cassandra and Opscenter Agent Docker images for a Docker standalone deployment or Kubernetes deployment.

NOTE: These build instructions are for building from an OS-X machine.  They should work for any Linux setup, just omit any boot2docker items.

## Prerequisites
* docker
	* boot2docker up
	* export the vars
	* $(boot2docker shellinit)
* GNU Make

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

#### Custom Java Seed Jar
Should only need this in very specific situations

* cd ../Java/KubSeedProv
* mvn clean
* mvn package
* copy target/KubSeedProv-1.0-SNAPSHOT.jar ../../cassandra/KubSeedProv-1.0-SNAPSHOT.jar

## Required For Git Push
* Make sure Dockerfile is a copy of the current build Dockerfile.kub.slim (or whatever).  This file will be used to build in quay.io.  This is for production, and the prod version will be built when this is merged to the samsungAG git repo.  The image should then be in quay.io/samaungAG/<>  repo.   You may need to set the version tag by hand.

* The Makefile is used for development and local builds.   It is possible to create a prod build with it also by setting the Repo env to quay.io/samsungAG.


