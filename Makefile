# SPDX-License-Identifier: GPL-2.0

ORG_NAME := hihg-um
OS_BASE ?= ubuntu
OS_VER ?= 18.04
PROJECT_NAME ?= python

USER ?= $$(USER)
USERID ?= `id -u`
USERGNAME ?= ad
USERGID ?= 1533

DOCKER_IMAGE_BASE := $(ORG_NAME)/$(USER)
DOCKER_TAG := latest

IMAGE_REPOSITORY := $(ORG_NAME)/$(USER)/$(PROJECT_NAME):latest

# Use this for debugging builds. Turn off for a more slick build log
DOCKER_BUILD_ARGS := --progress=plain


TOOLS := annopred
SIF_IMAGES := $(TOOLS:=\:$(DOCKER_TAG).svf)
#SIF_IMAGES := $(TOOLS)
DOCKER_IMAGES := $(TOOLS:=\:$(DOCKER_TAG))

.PHONY: all build clean test $(TOOLS)

all: docker test_docker apptainer test_apptainer

test: test_docker test_apptainer

clean:
	@docker rmi $(DOCKER_IMAGES)
	@rm -f $(SVF_IMAGES)

docker: $(TOOLS)

$(TOOLS):
	@docker build -t $(DOCKER_IMAGE_BASE)/$@:$(DOCKER_TAG) \
		$(DOCKER_BUILD_ARGS) \
		--build-arg BASE_IMAGE=$(OS_BASE):$(OS_VER) \
		--build-arg IMAGE_TOOLS="$(TOOLS)" \
		--build-arg USERNAME=$(USER) \
		--build-arg USERID=$(USERID) \
		--build-arg USERGNAME=$(USERGNAME) \
		--build-arg USERGID=$(USERGID) \
		--build-arg RUNCMD="$@" \
		.

test_docker: $(TOOLS)
	@echo "Testing docker image: $(DOCKER_IMAGE_BASE)/$<"
	@docker run -it -v /mnt:/mnt $(DOCKER_IMAGE_BASE)/$< --version

apptainer: $(SIF_IMAGES)
	make test_apptainer

$(SIF_IMAGES):
	echo "Building $@"
	@apptainer build $@ docker-daemon:$(DOCKER_IMAGE_BASE)/$(patsubst %.svf,%,$@)

test_apptainer: $(SIF_IMAGES)
	@echo "Testing apptainer image: $<"
	@apptainer run $< -v

release: $(DOCKER_IMAGES)
	@docker push $(IMAGE_REPOSITORY)/$(ORG_NAME)/$(USER)/$@
