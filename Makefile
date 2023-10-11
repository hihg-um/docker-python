# SPDX-License-Identifier: GPL-2.0

ORG_NAME := hihg-um
OS_BASE ?= ubuntu
OS_VER ?= 22.04

IMAGE_REPOSITORY :=
GIT_TAG := $(shell git tag)
GIT_REV := $(shell git describe --always --dirty)
DOCKER_TAG ?= $(GIT_TAG)-$(GIT_REV)

# Use this for debugging builds. Turn off for a more slick build log
DOCKER_BUILD_ARGS :=

TOOLS := python
DOCKER_IMAGES := $(TOOLS:=\:$(DOCKER_TAG))
SIF_IMAGES := $(TOOLS:=\:$(DOCKER_TAG).sif)

.PHONY: clean docker test test_apptainer test_docker $(DOCKER_IMAGES)

help:
	@echo "Targets: all clean test"
	@echo "         docker test_docker release_docker"
	@echo "         apptainer test_apptainer"
	@echo "Docker containers:\n$(DOCKER_IMAGES)"
	@echo
	@echo "Apptainer images:\n$(SIF_IMAGES)"

all: clean docker test_docker apptainer test_apptainer

clean:
	rm -f $(SIF_IMAGES)
	for f in $(TOOLS); do \
                docker rmi -f $(ORG_NAME)/$$f 2>/dev/null; \
        done

test: test_docker test_apptainer

$(TOOLS):
	@echo "Building Docker container $@"
	docker build -t $(ORG_NAME)/$@:$(DOCKER_TAG) \
                $(DOCKER_BUILD_ARGS) \
                --build-arg BASE_IMAGE=$(OS_BASE):$(OS_VER) \
                --build-arg RUN_CMD=$@ \
                .

docker: $(TOOLS)

test_docker: $(DOCKER_IMAGES)
	for f in $^; do \
	echo "Testing Docker container: $(ORG_NAME)/$$f"; \
	docker run -t --user $(id -u):$(id -g) -v /mnt:/mnt \
		$(ORG_NAME)/$$f --version; \
	done

release_docker: $(DOCKER_IMAGES)
	docker push $(IMAGE_REPOSITORY)/$(ORG_NAME)/$@

$(SIF_IMAGES):
	@echo "Building Apptainer $@"
	apptainer build $@ docker-daemon:$(ORG_NAME)/$(patsubst %.sif,%,$@)

apptainer: $(SIF_IMAGES)

test_apptainer: $(SIF_IMAGES)
	for f in $^; do \
		echo "Testing Apptainer image: $$f"; \
		apptainer run $$f --version; \
	done
