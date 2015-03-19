
.PHONY: all clean-app push
#
# This makefile assumes that docker is installed
#
# 3/19/2015 mln
#
VERSION = v2
REPO = mikeln

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
	@touch opscenter_kub_mln
	@docker images $(REPO)/opscenter_kub_mln

push:
	docker push $(REPO)/opscenter_kub_mln:$(VERSION)

clean: clean-app
	-rm -f Dockerfile

clean-app:
	-docker rmi $(REPO)/opscenter_kub_mln:$(VERSION)
	-rm -f opscenter_kub_mln

