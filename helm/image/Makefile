
.PHONY: all build-all build-app build-ops repo-warning push push-app push-ops clean clean-app clean-ops
#
# This makefile assumes that docker is installed
#
# 1/31/2017 mln
#
VERSION := v0.0.6
#
# do some repo evals... want everyone to use their own, unless building for the team
#
DEFAULT_REPO := "samsung-cnct"
DOCKER_REPO ?= $(DEFAULT_REPO)
REPO := $(DOCKER_REPO)
#
#
DOCKER_CASS_IMAGE := cassandra_dsc21
DOCKER_OPSC_IMAGE := opscenter_dsc21

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

build-all: build-app build-ops

build-app: $(DOCKER_CASS_IMAGE)

$(DOCKER_CASS_IMAGE): Dockerfile.dsc init-cass.sh stop-cass.sh
	@echo "building app $(VERSION)"
	docker build -f Dockerfile.dsc -t $(REPO)/$(DOCKER_CASS_IMAGE):$(VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_CASS_IMAGE)

build-ops: $(DOCKER_OPSC_IMAGE)

$(DOCKER_OPSC_IMAGE): Dockerfile.ops init-opsc.sh
	@echo "building ops $(VERSION)"
	docker build -f Dockerfile.ops -t $(REPO)/$(DOCKER_OPSC_IMAGE):$(VERSION) --rm=true --force-rm=true .
clean-app: 
	-docker rmi $(REPO)/$(DOCKER_CASS_IMAGE):$(VERSION)
	-rm -f $(DOCKER_CASS_IMAGE)

	@touch $@
	@docker images $(REPO)/$(DOCKER_OPSC_IMAGE)

push: push-app push-ops

push-app: 
	docker push $(REPO)/$(DOCKER_CASS_IMAGE):$(VERSION)

push-ops: 
	docker push $(REPO)/$(DOCKER_OPSC_IMAGE):$(VERSION)

clean: clean-app clean-ops

clean-app: 
	-docker rmi $(REPO)/$(DOCKER_CASS_IMAGE):$(VERSION)
	-rm -f $(DOCKER_CASS_IMAGE)

clean-ops: 
	-docker rmi $(REPO)/$(DOCKER_OPSC_IMAGE):$(VERSION)
	-rm -f $(DOCKER_OPSC_IMAGE)

