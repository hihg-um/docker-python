# SPDX-License-Identifier: GPL-2.0

IMAGE_REPO ?=
ORG_NAME ?= hihg-um
OS_BASE ?= ubuntu
OS_VER ?= 24.04

TOOLS := annopred python3 python3-scripting

ifneq ($(IMAGE_REPO),)
    DOCKER_REPO := $(IMAGE_REPO)/$(ORG_NAME)
else
    DOCKER_REPO := $(ORG_NAME)
endif

GIT_REPO := $(shell git remote get-url origin | sed 's,git@,,' | sed 's,:,/,')
GIT_REPO_TAIL := $(shell basename $(GIT_REPO) | sed 's/.git//' | \
			sed 's/docker-//')
GIT_TAG_HEAD ?= $(shell git describe --exact-match --tags --dirty 2>/dev/null)
GIT_TAG_LAST ?= $(shell git describe --abbrev=0 --always --tags)

ifeq ($(GIT_TAG_HEAD),$(GIT_TAG_LAST))
        GIT_LATEST := true
        GIT_TAG := $(GIT_TAG_HEAD)
        GIT_REV := $(shell git log -1 --pretty=format:%h)
        DOCKER_TAG := $(GIT_TAG)
else
        GIT_TAG := $(GIT_TAG_LAST)
        GIT_CNT := $(shell git rev-list $(GIT_TAG)..HEAD --count)
        GIT_REV := $(shell git describe --broken --dirty --all --long | \
			sed "s,heads/,," | sed "s,tags/,," | \
			sed "s,remotes/pull/.*/,,")
        DOCKER_TAG := $(GIT_REV)
endif

DOCKER_BASE := $(DOCKER_REPO)/$(GIT_REPO_TAIL):$(DOCKER_TAG)
DOCKER_IMAGES := $(TOOLS:=\:$(DOCKER_TAG))
DOCKER_IMAGES_TEST := $(DOCKER_IMAGES)

DOCKER_BUILD_TIME := "$(shell date -u)"
DOCKER_BUILD_OPTS ?= "--progress=plain"

SIF_IMAGES := $(TOOLS:=_$(DOCKER_TAG).sif)

IMAGE_TEST := /test.sh

.PHONY: apptainer_clean apptainer_distclean apptainer_test \
	docker_base docker_clean docker_release $(TOOLS)

help:
	@echo "Targets: all build clean test release"
	@echo "         docker docker_base docker_clean docker_test docker_release"
	@echo "         apptainer apptainer_clean apptainer_distclean apptainer_test"
	@echo
	@echo "Docker container(s):"
	@for f in $(DOCKER_IMAGES); do printf "\t$$f\n"; done
	@echo
	@echo "Apptainer(s):"
	@for f in $(SIF_IMAGES); do printf "\t$$f\n"; done
	@echo

all: clean build test

build: docker apptainer

clean: apptainer_clean docker_clean

release: docker_release

test: docker_test apptainer_test

# Docker
docker: docker_base $(TOOLS)

$(TOOLS):
	@echo "Building Docker container: $(DOCKER_REPO)/$@:$(DOCKER_TAG)"
	@docker build \
		$(DOCKER_BUILD_OPTS) \
		-f Dockerfile.$@ \
		-t $(DOCKER_REPO)/$@:$(DOCKER_TAG) \
		--build-arg BASE=$(DOCKER_BASE) \
		--build-arg RUN_CMD=$@ \
		--build-arg BUILD_REPO=$(DOCKER_REPO)/$@:$(DOCKER_TAG) \
		--build-arg BUILD_TIME=$(DOCKER_BUILD_TIME) \
		.
	$(if $(GIT_LATEST), \
		@docker tag \
		$(DOCKER_REPO)/$@:$(DOCKER_TAG) $(DOCKER_REPO)/$@:latest)

docker_base:
	@echo "Building Docker base: $(DOCKER_BASE)"
	@docker build -t $(DOCKER_BASE) \
		$(DOCKER_BUILD_OPTS) \
		--build-arg BASE=$(OS_BASE):$(OS_VER) \
		--build-arg GIT_REPO=$(GIT_REPO) \
		--build-arg GIT_REV=$(GIT_REV) \
		--build-arg GIT_TAG=$(GIT_TAG) \
		--build-arg BUILD_REPO=$(DOCKER_BASE) \
		.
	@docker inspect $(DOCKER_BASE)

docker_clean:
	@docker builder prune -f 1> /dev/null 2>& 1
	@for f in $(TOOLS); do \
		docker rmi -f $(DOCKER_REPO)/$$f:$(DOCKER_TAG) 1> /dev/null 2>& 1; \
	done
	@docker rmi -f $(DOCKER_BASE) 1> /dev/null 2>& 1

$(DOCKER_IMAGES_TEST):
	@echo
	@echo "Testing Docker container: $(DOCKER_REPO)/$@"
	@docker run -t \
		--entrypoint=$(IMAGE_TEST) \
		$(DOCKER_REPO)/$@

docker_test: $(DOCKER_IMAGES_TEST)

docker_release:
	$(if $(GIT_LATEST), \
		for f in $(GIT_REPO_TAIL) $(TOOLS); do \
			docker push $(DOCKER_REPO)/$$f:$(DOCKER_TAG); \
			docker push $(DOCKER_REPO)/$$f:latest; done, \
		$(info "Cannot push untagged build: $(GIT_TAG):$(GIT_REV)"))

# Apptainer
apptainer: $(SIF_IMAGES)

$(SIF_IMAGES):
	@for f in $(DOCKER_IMAGES); do \
		echo "Building Apptainer: $$f"; \
		apptainer pull docker-daemon:$(DOCKER_REPO)/$$f; \
	done

apptainer_clean:
	@for f in $(SIF_IMAGES); do \
		if [ -f "$$f" ]; then \
			printf "Cleaning up Apptainer: $$f\n"; \
			rm -f $$f; \
		fi \
	done

apptainer_distclean:
	@rm -f *.sif

apptainer_test: $(SIF_IMAGES)
	@for f in $^; do \
		echo "Testing Apptainer: $$f"; \
		apptainer exec $$f $(IMAGE_TEST); \
	done
