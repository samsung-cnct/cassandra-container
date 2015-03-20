
.PHONY: all build-all build-app repo-warning push clean clean-app
#
# This makefile assumes that docker is installed
#
# 3/12/2015 mln
#
VERSION := v9
#
# do some repo evals... want everyone to use their own, unless building for the team
#
DEFAULT_REPO := "samsungAG"
DOCKER_REPO ?= $(DEFAULT_REPO)
REPO := $(DOCKER_REPO)

repo-warning:
	@if  [ $(DOCKER_REPO) =  $(DEFAULT_REPO) ]; then \
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"; \
		echo "  You have not changed DOCKER_REPO from: $(DOCKER_REPO)"; \
		echo "  You MUST set DOCKER_REPO in your environment"; \
		echo "  or directly in this Makefile unless you are"; \
		echo "  building for the group"; \
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"; \
		false; \
	else \
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"; \
		echo "  Your DOCKER_REPO is set to: $(DOCKER_REPO)"; \
		echo "  Please execute 'make all' to build"; \
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"; \
	fi

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
	@touch $@
	@docker images $(REPO)/cassandra_kub_mln

KubSeedProv-1.0-SNAPSHOT.jar:
	@echo "=========================================================================="
	@echo "KubSeedProv-1.0-SNAPSHOT.jar is built in the java directory via mvn build"
	@echo "  You will have to build it by hand.  Build is not automated"
	@echo "=========================================================================="

push: 
	docker push $(REPO)/cassandra_kub_mln:$(VERSION)

clean: clean-app
	-rm -f Dockerfile

clean-app: 
	-docker rmi $(REPO)/cassandra_kub_mln:$(VERSION)
	-rm -f cassandra_kub_mln

