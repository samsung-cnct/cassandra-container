
.PHONY: all build-alpine-curl repo-warning push push-alpine-curl clean clean-alpine-curl
#
# This makefile assumes that docker is installed
#
# 1/31/2017 mln
#
ALPINE_CURL_VERSION := v1.0.0
#
# do some repo evals... want everyone to use their own, unless building for the team
#
DEFAULT_REPO := "samsung-cnct"
DOCKER_REPO ?= $(DEFAULT_REPO)
REPO := $(DOCKER_REPO)
#
#
# tools for dependency monitoring
DOCKER_ALPINE_CURL_FILE := Dockerfile.alpine-curl
DOCKER_ALPINE_CURL_IMAGE := alpine_curl

IMAGE_PUSH_COMMAND := $(shell if [[ $(DOCKER_REPO) =~ ^gcr.io/*  ]]; then \
	  echo "gcloud docker -- push"; \
	  else \
	  echo "docker push"; \
	  fi)

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

correct-push-command:
	echo "Using push command: ${IMAGE_PUSH_COMMAND}"

all: build-alpine-curl

build-alpine-curl: $(DOCKER_ALPINE_CURL_IMAGE)

$(DOCKER_ALPINE_CURL_IMAGE): $(DOCKER_ALPINE_CURL_FILE)
	@echo "building app $(ALPINE_CURL_VERSION)"
	docker build -f $(DOCKER_ALPINE_CURL_FILE) -t $(REPO)/$(DOCKER_ALPINE_CURL_IMAGE):$(ALPINE_CURL_VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_ALPINE_CURL_IMAGE)


push: push-alpine-curl

push-alpine-curl:
	$(IMAGE_PUSH_COMMAND) $(REPO)/$(DOCKER_ALPINE_CURL_IMAGE):$(AlPINE_CURL_VERSION)


clean: clean-alpine-curl

clean-alpine-curl: 
	-docker rmi $(REPO)/$(DOCKER_ALPINE_CURL_IMAGE):$(ALPINE_CURL_VERSION)
	-rm -f $(DOCKER_ALPINE_CURL_IMAGE)

