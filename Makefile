
OSTYPE := $(shell uname)
VERSION ?= $(shell git describe --tags --always)


IMAGE_NAME := slok/kahoy-app-deploy-example

DOCKER_RUN_CMD := docker run --env ostype=$(OSTYPE) -v ${PWD}:/src --rm ${IMAGE_NAME}
BUILD_IMAGE_CMD := IMAGE=${IMAGE_NAME} DOCKER_FILE_PATH=./Dockerfile VERSION=${VERSION} TAG_IMAGE_LATEST=true ./scripts/build-image.sh
PUBLISH_IMAGE_CMD := IMAGE=${IMAGE_NAME} VERSION=${VERSION} TAG_IMAGE_LATEST=true ./scripts/publish-image.sh

GEN_CMD := ./scripts/generate.sh
CHECK_CMD := ./scripts/check.sh


help: ## Show this help.
	@echo "Help"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-20s\033[93m %s\n", $$1, $$2}'

.PHONY: default
default: help

.PHONY: build-image
build-image: ## Builds docker image.
	@$(BUILD_IMAGE_CMD)

.PHONY: publish-image
publish-image: ## Publishes the production docker image.
	@$(PUBLISH_IMAGE_CMD)

.PHONY: gen
gen: ## Generates manifests.
	@$(DOCKER_RUN_CMD) /bin/sh -c '$(GEN_CMD)'

.PHONY: generate
generate: gen ## Generates manifests.

.PHONY: check
check: ## Checks generated manifests are up to date.
	@$(DOCKER_RUN_CMD) /bin/sh -c '$(CHECK_CMD)'