
.PHONY: all clean-app
#
# This makefile assumes that docker is installed
#
# 3/12/2015 mln
#
VERSION = v7
REPO = mikeln

all: build-all

build-all: build-app

build-app: cassandra_kub_mln

cassandra_kub_mln: Dockerfile.kub init.sh KubSeedProv-1.0-SNAPSHOT.jar
	@echo "building app $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.kub Dockerfile
	#docker build -f Dockerfile.inject -t $(REPO)/twissandra_img:$(VERSION) .
	docker build -t $(REPO)/cassandra_kub_mln:$(VERSION) --rm=true --force-rm=true .
	@touch cassandra_kub_mln
	@docker images $(REPO)/cassandra_kub_mln

clean: clean-app
	-rm -f Dockerfile

clean-app:
	-docker rmi $(REPO)/cassandra_kub_mln:$(VERSION)
	-rm -f cassandra_kub_mln

