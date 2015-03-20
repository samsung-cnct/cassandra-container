# cassandra-container Docker Only Version

Standlone/Clustered Datastax Community running on top of a Ubuntu-based Docker image with opscenter agent

Verion for Docker 

This was started from the docker-cassandra project and enhanced (substantially)

## Assumptions

opscenter container must be run first and be named:

	opscenter

cassandra seed containers must be named one of the following: 

	cass1
	cass2
	cass3
	cass4
	cass5
	cass6
	cass7
	cass8
	cass9
	
cassandra containers must be linked to the opscenter container. This is needed to set the STOMP IP in the datastax-agent for the opscenter.

Note: any linked cassX containers are considered SEEDs.

## Container Architecture
### Docker
	
## Build Instructions
see [BUILD](./BUILD.md)

## Command Line Instructions
### Docker
Three node cluster with opscenter

	docker run -d --name opscenter -p 8888:8888 <repo>/opsenter-mln:<version>
	docker run -d --name cass1 --link opscenter:opscenter <repo>/cassandra-mln:<version>
	docker run -d --name cass2 --link opscenter:opscenter --link cass1:cass1 <repo>/cassandra-mln:<version>
	docker run -d --name cass3 --link opscenter:opscenter --link cass1:cass1  <repo>/cassandra-mln:<version>

Debug help
	
	docker exec -it <container name> bash
	
Browser URL (boot2docker)

	boot2docker ip
	http://<boot2docker ip>:8888
	
	docker inspect cass1  (look for NetworkSettings.IPAddress)
	Connet to existing cluster in web UI popup.  Supply the IP address.
	
