
.PHONY: all biuld-all build-app repo-warning clean-app push clean
#
# This makefile assumes that docker is installed
#
# 3/19/2015 mln
#
VERSION := v2
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

build-app: opscenter_kub_mln

opscenter_kub_mln: Dockerfile.kub init.sh 
	@echo "building app $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.kub Dockerfile
	#docker build -f Dockerfile.inject -t $(REPO)/opscenter_kub_mln:$(VERSION) .
	docker build -t $(REPO)/opscenter_kub_mln:$(VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/opscenter_kub_mln

push:
	docker push $(REPO)/opscenter_kub_mln:$(VERSION)

clean: clean-app
	-rm -f Dockerfile

clean-app:
	-docker rmi $(REPO)/opscenter_kub_mln:$(VERSION)
	-rm -f opscenter_kub_mln

