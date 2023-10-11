# SPDX-License-Identifier: GPL-2.0

ORG_NAME := hihg-um
OS_BASE ?= ubuntu
OS_VER ?= 22.04

IMAGE_REPOSITORY ?=
DOCKER_IMAGE_BASE := $(ORG_NAME)

GIT_REV := $(shell git describe --tags --dirty)
DOCKER_TAG ?= $(GIT_REV)

DOCKER_BUILD_ARGS :=

TOOLS := polars
DOCKER_BASE= python-base\:$(DOCKER_TAG)
DOCKER_IMAGES := $(TOOLS:=\:$(DOCKER_TAG))
SIF_IMAGES := $(TOOLS:=\:$(DOCKER_TAG).sif)

.PHONY: clean docker test $(DOCKER_IMAGES) $(TOOLS)

all: docker apptainer test

help:
	@echo "Targets: all clean test"
	@echo "         docker docker_clean docker_test docker_release"
	@echo "         apptainer apptainer_clean apptainer_test"
	@echo
	@echo "Docker containers:\n$(DOCKER_IMAGES)"
	@echo
	@echo "Apptainer images:\n$(SIF_IMAGES)"

clean: apptainer_clean docker_clean

release: apptainer_release docker_release

test: apptainer_test docker_test

# Docker
docker_clean:
	for f in $(DOCKER_IMAGES); do \
		docker rmi -f $(DOCKER_IMAGE_BASE)/$$f 2>/dev/null; \
	done
	@docker rmi -f $(DOCKER_IMAGE_BASE)/$(DOCKER_BASE) 2>/dev/null;

docker: $(DOCKER_BASE) $(TOOLS)

$(DOCKER_BASE):
	@echo "Building Docker base container $@"
	@docker build \
		-t $(DOCKER_IMAGE_BASE)/$(DOCKER_BASE) \
		$(DOCKER_BUILD_ARGS) \
		--build-arg BASE_IMAGE=$(OS_BASE):$(OS_VER) \
		.

$(TOOLS):
	@echo "Building Docker container $(DOCKER_IMAGE_BASE)/$@:$(DOCKER_TAG)"
	@docker build \
		-t $(DOCKER_IMAGE_BASE)/$@:$(DOCKER_TAG) \
		$(DOCKER_BUILD_ARGS) \
		-f ./Dockerfile.$@ \
		--build-arg BASE_IMAGE=$(DOCKER_IMAGE_BASE)/$(DOCKER_BASE) \
		--build-arg RUNCMD="$@" \
		.

docker_test:
	for f in $(DOCKER_IMAGES); do \
		echo "Testing Docker image: $(DOCKER_IMAGE_BASE)/$$f"; \
		docker run -t $(DOCKER_IMAGE_BASE)/$$f --version; \
	done

docker_release: $(DOCKER_IMAGES)
	for f in $(DOCKER_IMAGES); do \
		docker push $(IMAGE_REPOSITORY)/$(DOCKER_IMAGE_BASE)/$$f; \
	done

# Apptainer
apptainer_clean:
	rm -f $(SIF_IMAGES)

apptainer: $(SIF_IMAGES)

$(SIF_IMAGES):
	@echo "Building Apptainer $@"
	@apptainer build $@ \
		docker-daemon:$(DOCKER_IMAGE_BASE)/$(patsubst %.sif,%,$@)

apptainer_test: $(SIF_IMAGES)
	for f in $(SIF_IMAGES); do \
		echo "Testing Apptainer image: $$f"; \
		apptainer run $$f --version; \
	done

apptainer_release: $(SIF_IMAGES)
