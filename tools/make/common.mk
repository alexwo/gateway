# This is a wrapper to set common variables
#
# All make targets related to common variables are defined in this file.

# ====================================================================================================
# ROOT Options:
# ====================================================================================================

ROOT_PACKAGE=github.com/envoyproxy/gateway

# ====================================================================================================
# Includes:
# ====================================================================================================
include tools/make/golang.mk
include tools/make/image.mk
include tools/make/lint.mk
include tools/make/kube.mk

# Set Root Directory Path
ifeq ($(origin ROOT_DIR),undefined)
ROOT_DIR := $(abspath $(shell  pwd -P))
endif

# Set Output Directory Path
ifeq ($(origin OUTPUT_DIR),undefined)
OUTPUT_DIR := $(ROOT_DIR)/bin
endif

# Set the version number. you should not need to do this
# for the majority of scenarios.
ifeq ($(origin VERSION), undefined)
VERSION := $(shell git describe --abbrev=0 --dirty --always --tags | sed 's/-/./g')
endif

# REV is the short git sha of latest commit.
REV=$(shell git rev-parse --short HEAD)

# Supported Platforms for building multiarch binaries.
PLATFORMS ?= darwin_amd64 darwin_arm64 linux_amd64 linux_arm64 

# Set a specific PLATFORM
ifeq ($(origin PLATFORM), undefined)
	ifeq ($(origin GOOS), undefined)
		GOOS := $(shell go env GOOS)
	endif
	ifeq ($(origin GOARCH), undefined)
		GOARCH := $(shell go env GOARCH)
	endif
	PLATFORM := $(GOOS)_$(GOARCH)
	# Use linux as the default OS when building images
	IMAGE_PLAT := linux_$(GOARCH)
else
	GOOS := $(word 1, $(subst _, ,$(PLATFORM)))
	GOARCH := $(word 2, $(subst _, ,$(PLATFORM)))
	IMAGE_PLAT := $(PLATFORM)
endif

# List commands in cmd directory for building targets
COMMANDS ?= $(wildcard ${ROOT_DIR}/cmd/*)
BINS ?= $(foreach cmd,${COMMANDS},$(notdir ${cmd}))

ifeq (${COMMANDS},)
  $(error Could not determine COMMANDS, set ROOT_DIR or run in source dir)
endif
ifeq (${BINS},)
  $(error Could not determine BINS, set ROOT_DIR or run in source dir)
endif

# Log the running target
LOG_TARGET = echo "===========> Running $@..."
# Log debugging info
define log
echo "===========> $1"
endef


define USAGE_OPTIONS

Options:
  \033[36mMAKE_IN_DOCKER\033[0m	
		 Run make inside a Docker container which has all the preinstalled tools needed to support all the make targets
		 This option is available to all cmds.
		 Example: \033[36mmake build MAKE_IN_DOCKER=1\033[0m
  \033[36mBINS\033[0m       
		 The binaries to build. Default is all of cmd.
		 This option is available when using: make build|build-multiarch
		 Example: \033[36mmake build BINS="envoy-gateway"\033[0m
  \033[36mIMAGES\033[0m     
		 Backend images to make. Default is all of cmds.
		 This option is available when using: make image|image-multiarch|push|push-multiarch
		 Example: \033[36mmake image-multiarch IMAGES="envoy-gateway"\033[0m
  \033[36mPLATFORM\033[0m   
		 The specified platform to build.
		 This option is available when using: make build|image
		 Example: \033[36mmake build BINS="envoy-gateway" PLATFORM="linux_amd64""\033[0m
		 Supported Platforms: linux_amd64 linux_arm64 darwin_amd64 darwin_arm64
  \033[36mPLATFORMS\033[0m  
		 The multiple platforms to build.
		 This option is available when using: make build-multiarch
		 Example: \033[36mmake build-multiarch BINS="envoy-gateway" PLATFORMS="linux_amd64 linux_arm64"\033[0m
		 Default is "linux_amd64 linux_arm64 darwin_amd64 darwin_arm64".
endef
export USAGE_OPTIONS

## help: Show this help info.
.PHONY: help
help:
	@echo "Envoy Gateway is an open source project for managing Envoy Proxy as a standalone or Kubernetes-based application gateway\n"
	@echo "Usage:\n  make \033[36m<Target>\033[0m \033[36m<Option>\033[0m\n\nTargets:"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo "$$USAGE_OPTIONS"