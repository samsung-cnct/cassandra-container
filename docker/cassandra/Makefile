
.PHONY: all build-all build-app repo-warning push clean clean-app
#
# This makefile assumes that docker is installed
#
# 3/12/2015 mln
#
VERSION := v4
#
# do some repo evals... want everyone to use their own, unless building for the team
#
DEFAULT_REPO := "samsung-cnct"
DOCKER_REPO ?= $(DEFAULT_REPO)
REPO := $(DOCKER_REPO)
#
#
DOCKER_IMAGE := cassandra_mln

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

build-app: $(DOCKER_IMAGE)

$(DOCKER_IMAGE): Dockerfile.app init.sh 
	@echo "building app $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.app Dockerfile
	#docker build -f Dockerfile.app -t $(REPO)/$(DOCKER_IMAGE):$(VERSION) .
	docker build -t $(REPO)/$(DOCKER_IMAGE):$(VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_IMAGE)

KubSeedProv-1.0-SNAPSHOT.jar:
	@echo "=========================================================================="
	@echo "KubSeedProv-1.0-SNAPSHOT.jar is built in the java directory via mvn build"
	@echo "  You will have to build it by hand.  Build is not automated"
	@echo "=========================================================================="

push: 
	docker push $(REPO)/$(DOCKER_IMAGE):$(VERSION)

clean: clean-app
	-rm -f Dockerfile

clean-app: 
	-docker rmi $(REPO)/$(DOCKER_IMAGE):$(VERSION)
	-rm -f $(DOCKER_IMAGE)

