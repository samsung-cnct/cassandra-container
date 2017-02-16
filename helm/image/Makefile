
.PHONY: all build-dsc dse-app dse-ops cass-app cass-ops repo-warning push push-dsc push-ops clean clean-dsc clean-ops
#
# This makefile assumes that docker is installed
#
# 1/31/2017 mln
#
DSC_IMG_VERSION := v2.0.0
DSE_IMG_VERSION := v2.0.0
#
# do some repo evals... want everyone to use their own, unless building for the team
#
DEFAULT_REPO := "samsung-cnct"
DOCKER_REPO ?= $(DEFAULT_REPO)
REPO := $(DOCKER_REPO)
#
#
DOCKER_CASS_IMAGE := cassandra_dsc21
DOCKER_CASS_FILE := Dockerfile.dsc-dsc
DOCKER_OPSC_IMAGE := opscenter_dsc21
DOCKER_OPSC_FILE := Dockerfile.dsc-ops

DOCKER_DSE_IMAGE := cassandra_dse
DOCKER_DSE_FILE := Dockerfile.dse-dse
DOCKER_EPS_IMAGE := opscenter_dse
DOCKER_EPS_FILE := Dockerfile.dse-ops
# secured version
DOCKER_CASS_SEC_IMAGE := cassandra_dsc21_sec
DOCKER_CASS_SEC_FILE := Dockerfile.dsc-dsc-sec
DOCKER_OPSC_SEC_IMAGE := opscenter_dsc21_sec
DOCKER_OPSC_SEC_FILE := Dockerfile.dsc-ops-sec

DOCKER_DSE_SEC_IMAGE := cassandra_dse_sec
DOCKER_DSE_SEC_FILE := Dockerfile.dse-dse-sec
DOCKER_EPS_SEC_IMAGE := opscenter_dse_sec
DOCKER_EPS_SEC_FILE := Dockerfile.dse-ops-sec

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

all: build-dsc build-dse build-dsc-sec build-dse-sec

build-dsc: cass-app cass-ops

build-dse: dse-app dse-ops

build-dsc-sec: cass-app-sec cass-ops-sec

build-dse-sec: dse-app-sec dse-ops-sec

cass-app: $(DOCKER_CASS_IMAGE)

$(DOCKER_CASS_IMAGE): $(DOCKER_CASS_FILE) init-cass.sh stop-cass.sh
	@echo "building app $(DSC_IMG_VERSION)"
	docker build -f $(DOCKER_CASS_FILE) -t $(REPO)/$(DOCKER_CASS_IMAGE):$(DSC_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_CASS_IMAGE)

cass-ops: $(DOCKER_OPSC_IMAGE)

$(DOCKER_OPSC_IMAGE): $(DOCKER_OPSC_FILE) init-opsc.sh
	@echo "building ops $(DSC_IMG_VERSION)"
	docker build -f $(DOCKER_OPSC_FILE) -t $(REPO)/$(DOCKER_OPSC_IMAGE):$(DSC_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_OPSC_IMAGE)

dse-app: $(DOCKER_DSE_IMAGE)

$(DOCKER_DSE_IMAGE): $(DOCKER_DSE_FILE) init-cass.sh stop-cass.sh
	@echo "building app $(DSE_IMG_VERSION)"
	docker build -f $(DOCKER_DSE_FILE) -t $(REPO)/$(DOCKER_DSE_IMAGE):$(DSE_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_DSE_IMAGE)

dse-ops: $(DOCKER_EPS_IMAGE)

$(DOCKER_EPS_IMAGE): $(DOCKER_EPS_FILE) init-opsc.sh
	@echo "building ops $(DSE_IMG_VERSION)"
	docker build -f $(DOCKER_EPS_FILE) -t $(REPO)/$(DOCKER_EPS_IMAGE):$(DSE_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_EPS_IMAGE)

#------
cass-app-sec: $(DOCKER_CASS_SEC_IMAGE)

$(DOCKER_CASS_SEC_IMAGE): $(DOCKER_CASS_SEC_FILE) init-cass.sh stop-cass.sh
	@echo "building app $(DSC_IMG_VERSION)"
	docker build -f $(DOCKER_CASS_SEC_FILE) -t $(REPO)/$(DOCKER_CASS_SEC_IMAGE):$(DSC_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_CASS_SEC_IMAGE)

cass-ops-sec: $(DOCKER_OPSC_SEC_IMAGE)

$(DOCKER_OPSC_SEC_IMAGE): $(DOCKER_OPSC_SEC_FILE) init-opsc.sh
	@echo "building ops $(DSC_IMG_VERSION)"
	docker build -f $(DOCKER_OPSC_SEC_FILE) -t $(REPO)/$(DOCKER_OPSC_SEC_IMAGE):$(DSC_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_OPSC_SEC_IMAGE)

dse-app-sec: $(DOCKER_DSE_SEC_IMAGE)

$(DOCKER_DSE_SEC_IMAGE): $(DOCKER_DSE_SEC_FILE) init-cass.sh stop-cass.sh
	@echo "building app $(DSE_IMG_VERSION)"
	docker build -f $(DOCKER_DSE_SEC_FILE) -t $(REPO)/$(DOCKER_DSE_SEC_IMAGE):$(DSE_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_DSE_SEC_IMAGE)

dse-ops-sec: $(DOCKER_EPS_SEC_IMAGE)

$(DOCKER_EPS_SEC_IMAGE): $(DOCKER_EPS_SEC_FILE) init-opsc.sh
	@echo "building ops $(DSE_IMG_VERSION)"
	docker build -f $(DOCKER_EPS_SEC_FILE) -t $(REPO)/$(DOCKER_EPS_SEC_IMAGE):$(DSE_IMG_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_EPS_SEC_IMAGE)

push: push-dsc push-dse push-dsc-sec push-dse-sec

push-dsc: push-dsc-cass push-dsc-ops

push-dse: push-dse-cass push-dse-ops

push-dsc-sec: push-dsc-cass-sec push-dsc-ops-sec

push-dse-sec: push-dse-cass-sec push-dse-ops-sec

push-dsc-cass: 
	docker push $(REPO)/$(DOCKER_CASS_IMAGE):$(DSC_IMG_VERSION)

push-dsc-ops: 
	docker push $(REPO)/$(DOCKER_OPSC_IMAGE):$(DSC_IMG_VERSION)

push-dse-cass: 
	docker push $(REPO)/$(DOCKER_DSE_IMAGE):$(DSE_IMG_VERSION)

push-dse-ops: 
	docker push $(REPO)/$(DOCKER_EPS_IMAGE):$(DSE_IMG_VERSION)

#-----

push-dsc-cass-sec: 
	docker push $(REPO)/$(DOCKER_CASS_SEC_IMAGE):$(DSC_IMG_VERSION)

push-dsc-ops-sec: 
	docker push $(REPO)/$(DOCKER_OPSC_SEC_IMAGE):$(DSC_IMG_VERSION)

push-dse-cass-sec: 
	docker push $(REPO)/$(DOCKER_DSE_SEC_IMAGE):$(DSE_IMG_VERSION)

push-dse-ops-sec: 
	docker push $(REPO)/$(DOCKER_EPS_SEC_IMAGE):$(DSE_IMG_VERSION)


clean: clean-dsc clean-dse clean-dsc-sec clean-dse-sec

clean-dsc: clean-dsc-cass clean-dsc-ops

clean-dse: clean-dse-cass clean-dse-ops

clean-dsc-sec: clean-dsc-cass-sec clean-dsc-ops-sec

clean-dse-sec: clean-dse-cass-sec clean-dse-ops-sec

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

#-----

clean-dsc-cass-sec: 
	-docker rmi $(REPO)/$(DOCKER_CASS_SEC_IMAGE):$(DSC_IMG_VERSION)
	-rm -f $(DOCKER_CASS_SEC_IMAGE)

clean-dsc-ops-sec: 
	-docker rmi $(REPO)/$(DOCKER_OPSC_SEC_IMAGE):$(DSC_IMG_VERSION)
	-rm -f $(DOCKER_OPSC_SEC_IMAGE)

clean-dse-cass-sec: 
	-docker rmi $(REPO)/$(DOCKER_DSE_SEC_IMAGE):$(DSE_IMG_VERSION)
	-rm -f $(DOCKER_DSE_SEC_IMAGE)

clean-dse-ops-sec: 
	-docker rmi $(REPO)/$(DOCKER_EPS_SEC_IMAGE):$(DSE_IMG_VERSION)
	-rm -f $(DOCKER_EPS_SEC_IMAGE)


