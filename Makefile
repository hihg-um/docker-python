# SPDX-License-Identifier: GPL-2.0

ORG_NAME := hihg-um
PROJECT_NAME ?= python3_10

OS_BASE ?= ubuntu
OS_VER ?= 22.04

USER ?= `whoami`
USERID := `id -u`
USERGID := 5001
USERGNAME := ad

IMAGE_REPOSITORY := $(ORG_NAME)/$(USER)/$(PROJECT_NAME):latest

# Use this for debugging builds. Turn off for a more slick build log
DOCKER_BUILD_ARGS := --progress=plain

.PHONY: all build clean test tests

all: docker test
tests: test

test:

clean:
	@docker rmi $(IMAGE_REPOSITORY)

docker:
	@docker build -t $(IMAGE_REPOSITORY) \
		--build-arg BASE_IMAGE=$(OS_BASE):$(OS_VER) \
		--build-arg USERNAME=$(USER) \
		--build-arg USERID=$(USERID) \
		--build-arg USERGNAME=$(USERGNAME) \
		--build-arg USERGID=$(USERGID) \
		$(DOCKER_BUILD_ARGS) \
	  .

release:
	docker push $(IMAGE_REPOSITORY)
