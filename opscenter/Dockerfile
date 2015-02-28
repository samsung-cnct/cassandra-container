##
##    Cassandra opscenter
##
##

FROM ubuntu
MAINTAINER Mikel Nelson <mikel.n@samsung.com>

# Add PPA for the necessary JDK
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee /etc/apt/sources.list.d/webupd8team-java.list
RUN echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
RUN apt-get update

# Install other packages
RUN apt-get install -y curl

# Install Cassandra
RUN echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.sources.list
RUN curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
RUN apt-get update

RUN apt-get -y install opscenter

# Deploy startup script
ADD init.sh /usr/local/bin/ops-dock
RUN chmod 755 /usr/local/bin/ops-dock

# Deploy shutdown script
ADD shutdown.sh /usr/local/bin/ops-stop
RUN chmod 755 /usr/local/bin/ops-stop

EXPOSE 7199 7000 7001 9160 9042
EXPOSE 61620 61621 50031
#v1 EXPOSE 22 61620 61621 50031
USER root
CMD ops-dock
