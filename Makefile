TOPDIR=$(dir $(lastword $(MAKEFILE_LIST)))

DOCKERFILE_DIR     ?= ./
DOCKER_CMD         ?= docker
DOCKER_REGISTRY    ?= docker.io
DOCKER_ORG         ?= witcom
DOCKER_TAG         ?= $(shell cat $(TOPDIR)/release.version)
BUILD_TAG          ?= latest
PROJECT_NAME       ?= vaultwarden-s3-backup

all: docker_build docker_push

docker_build_default:
	# Build Docker image ...
	$(DOCKER_CMD) $(DOCKER_BUILDX) build $(DOCKER_PLATFORM) $(DOCKER_BUILD_ARGS) -t $(DOCKER_ORG)/$(PROJECT_NAME):latest $(DOCKERFILE_DIR)
#   The Dockerfiles all use FROM ...:latest, so it is necessary to tag images with latest (-t above)
	# Also tag with $(BUILD_TAG)
	$(DOCKER_CMD) tag $(DOCKER_ORG)/$(PROJECT_NAME):latest $(DOCKER_ORG)/$(PROJECT_NAME):$(BUILD_TAG)$(DOCKER_PLATFORM_TAG_SUFFIX)

docker_tag_default:
	# Tag the $(BUILD_TAG) image we built with the given $(DOCKER_TAG) tag
	$(DOCKER_CMD) tag $(DOCKER_ORG)/$(PROJECT_NAME):$(BUILD_TAG)$(DOCKER_PLATFORM_TAG_SUFFIX) $(DOCKER_REGISTRY)/$(DOCKER_ORG)/$(PROJECT_NAME):$(DOCKER_TAG)$(DOCKER_PLATFORM_TAG_SUFFIX)
	# Tag the $(BUILD_TAG) image we built with the latest tag
	$(DOCKER_CMD) tag $(DOCKER_ORG)/$(PROJECT_NAME):$(BUILD_TAG)$(DOCKER_PLATFORM_TAG_SUFFIX) $(DOCKER_REGISTRY)/$(DOCKER_ORG)/$(PROJECT_NAME):latest$(DOCKER_PLATFORM_TAG_SUFFIX)

docker_push_default: docker_tag
	# Push the $(DOCKER_TAG)-tagged image to the registry
	$(DOCKER_CMD) push $(DOCKER_REGISTRY)/$(DOCKER_ORG)/$(PROJECT_NAME):$(DOCKER_TAG)$(DOCKER_PLATFORM_TAG_SUFFIX)
	# Push the latest-tagged image to the registry
	$(DOCKER_CMD) push $(DOCKER_REGISTRY)/$(DOCKER_ORG)/$(PROJECT_NAME):latest$(DOCKER_PLATFORM_TAG_SUFFIX)

docker_%: docker_%_default
	@  true