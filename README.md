# cassandra-container

Standlone/Clustered Datastax Community running on top of a Ubuntu-based Docker image with opscenter agent

Verions for Docker and Kubernetes

This was started from the docker-cassandra project and enhanced (substantially)

## Container Architecture
### Docker
	
![Docker Architecture](./DockerArch.png?raw=true)
	
### Kubernetes
**NOTE: STILL A WORK IN PROGRESS!!**
![Kubernetes Architecture](./KubernetesArch.png?raw=true)
	
## Build Instructions
There are currently separate builds for Docker alone images vs Images for Kubernetes. (this will change shortly).   You should only have to build images in specical cases.  Normally you should run using the images already in a (the) Docker Repository.

However, if you must build, see the Makefile(s) in the lower level directories.

## Command Line Instructions
### Docker
Three node cluster with opscenter

See the docker directory [README](/docker/README.md)	
	
### Kubernetes
Two/Three node cluster with opscenter

See the kubernetes directory [README](/kubernetes/README.md)




