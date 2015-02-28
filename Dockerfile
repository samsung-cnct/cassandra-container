##
##    Cassandra
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

# Preemptively accept the Oracle License
RUN echo "oracle-java7-installer	shared/accepted-oracle-license-v1-1	boolean	true" > /tmp/oracle-license-debconf
RUN /usr/bin/debconf-set-selections /tmp/oracle-license-debconf
RUN rm /tmp/oracle-license-debconf

# Install the JDK
RUN apt-get install -y oracle-java7-installer oracle-java7-set-default
RUN apt-get update

# Install Cassandra
RUN echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.sources.list
RUN curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
RUN apt-get update
#
# some discrepancies here (even from Datastax itself)
#
# this should be the "stable community edition"
RUN apt-get install -y dsc20=2.0.11-1 cassandra=2.0.11 
# this is the "dev community edition"
#RUN apt-get install -y dsc21 # one build uses this
# not sure what version this one is.
#RUN apt-get install -y cassandra # kubernetes image uses this
#
#--------------------------------------------
# Cassandra visualizer/control tool
#
RUN apt-get install -y datastax-agent
#
# NOTE: iostat appears to be missing from ubuntu (used y datastax)...need the following package
RUN apt-get install -y sysstat
#
# TODO: NEED TO SET THE UI SERVER IP FIRST!...but we don't know it????
#
#RUN echo "stomp_interface: <reachable_opscenterd_ip>" | sudo tee -a /var/lib/datastax-agent/conf/address.yaml
#
# Also need (supposedly) sshd for this to work correctly
#
# Configure SSH server
#v1 RUN apt-get install -y openssh-server
#v1 RUN apt-get install -y openssh-client
# Create OpsCenter account
#v1 RUN rm -rf /etc/ssh/ssh_host_rsa_key
#v1 RUN mkdir -p /var/run/sshd && chmod -rx /var/run/sshd && \
#v1     ssh-keygen -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key && \
#v1     sed -ri 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config && \
#v1     sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
#v1     sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config && \
#v1     useradd -m -G users,root -p $(openssl passwd -1 "opscenter") opscenter && \
#v1     echo "%root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
#
# Start the datastax-agent
#RUN service datastax-agent start  
# DO THIS IN THE SCRIPT INSTEAD
#-----------------------------------------------

# Deploy startup script
ADD init.sh /usr/local/bin/cass-dock
RUN chmod 755 /usr/local/bin/cass-dock

# Deploy shutdown script
ADD shutdown.sh /usr/local/bin/cass-stop
RUN chmod 755 /usr/local/bin/cass-stop

EXPOSE 7199 7000 7001 9160 9042
EXPOSE 61620 61621 50031
#v1 EXPOSE 22 61620 61621 50031
USER root
CMD cass-dock
