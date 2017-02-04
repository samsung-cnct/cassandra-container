
.PHONY: all build-dsc dse-app dse-ops cass-app cass-ops repo-warning push push-dsc push-ops clean clean-dsc clean-ops
#
# This makefile assumes that docker is installed
#
# 1/31/2017 mln
#
DSC_IMG_VERSION := v0.0.7
DSE_IMG_VERSION := v0.0.9
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
DOCKER_DSE_IMAGE := cassandra_dse
DOCKER_EPS_IMAGE := opscenter_dse

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

all: build-dsc build-dse

build-dsc: cass-app cass-ops

build-dse: dse-app dse-ops

cass-app: $(DOCKER_CASS_IMAGE)

$(DOCKER_CASS_IMAGE): Dockerfile.dsc init-cass.sh stop-cass.sh
	@echo "building app $(DSC_IMG_VERSION)"
	docker build -f Dockerfile.dsc -t $(REPO)/$(DOCKER_CASS_IMAGE):$(DSC_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_CASS_IMAGE)

cass-ops: $(DOCKER_OPSC_IMAGE)

$(DOCKER_OPSC_IMAGE): Dockerfile.ops init-opsc.sh
	@echo "building ops $(DSC_IMG_VERSION)"
	docker build -f Dockerfile.ops -t $(REPO)/$(DOCKER_OPSC_IMAGE):$(DSC_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_OPSC_IMAGE)

dse-app: $(DOCKER_DSE_IMAGE)

$(DOCKER_DSE_IMAGE): Dockerfile.dse init-cass.sh stop-cass.sh
	@echo "building app $(DSE_IMG_VERSION)"
	docker build -f Dockerfile.dse -t $(REPO)/$(DOCKER_DSE_IMAGE):$(DSE_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_DSE_IMAGE)

dse-ops: $(DOCKER_EPS_IMAGE)

$(DOCKER_EPS_IMAGE): Dockerfile.eps init-opsc.sh
	@echo "building ops $(DSE_IMG_VERSION)"
	docker build -f Dockerfile.eps -t $(REPO)/$(DOCKER_EPS_IMAGE):$(DSE_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_EPS_IMAGE)

push: push-dsc push-dse

push-dsc: push-dsc-cass push-dsc-ops

push-dse: push-dse-cass push-dse-ops

push-dsc-cass: 
	docker push $(REPO)/$(DOCKER_CASS_IMAGE):$(DSC_IMG_VERSION)

push-dsc-ops: 
	docker push $(REPO)/$(DOCKER_OPSC_IMAGE):$(DSC_IMG_VERSION)

push-dse-cass: 
	docker push $(REPO)/$(DOCKER_DSE_IMAGE):$(DSE_IMG_VERSION)

push-dse-ops: 
	docker push $(REPO)/$(DOCKER_EPS_IMAGE):$(DSE_IMG_VERSION)

clean: clean-dsc clean-dse

clean-dsc: clean-dsc-cass clean-dsc-ops

clean-dse: clean-dse-cass clean-dse-ops

clean-dsc-cass: 
	-docker rmi $(REPO)/$(DOCKER_CASS_IMAGE):$(DSC_IMG_VERSION)
	-rm -f $(DOCKER_CASS_IMAGE)

clean-dsc-ops: 
	-docker rmi $(REPO)/$(DOCKER_OPSC_IMAGE):$(DSC_IMG_VERSION)
	-rm -f $(DOCKER_OPSC_IMAGE)

clean-dse-cass: 
	-docker rmi $(REPO)/$(DOCKER_DSE_IMAGE):$(DSE_IMG_VERSION)
	-rm -f $(DOCKER_DSE_IMAGE)

clean-dse-ops: 
	-docker rmi $(REPO)/$(DOCKER_EPS_IMAGE):$(DSE_IMG_VERSION)
	-rm -f $(DOCKER_EPS_IMAGE)
