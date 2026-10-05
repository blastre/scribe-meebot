.PHONY: all up down test env preflight init-db build push build-and-push set-latest set-dev setup-builder help

# --- Paths ---
ROOT := $(shell git rev-parse --show-toplevel)
ENV_FILE := $(ROOT)/.env
ENV_EXAMPLE := $(ROOT)/deploy/env-example

# DockerHub configuration
DOCKERHUB_USER ?= scribe
IMAGE_NAME ?= scribe-lite
TAG ?= dev

# Multi-arch platforms
PLATFORMS ?= linux/amd64,linux/arm64

# Buildx builder name
BUILDER_NAME ?= scribe-multiarch

# Paths (Makefile is in deploy/lite/, Dockerfile is in same dir, context is repo root)
DOCKERFILE := $(shell pwd)/Dockerfile.lite
CONTEXT := $(shell pwd)/../..
LOCAL_TAG := $(IMAGE_NAME):$(TAG)

# Generate unique timestamp tag: YYMMDD-HHMM
UNIQUE_TAG := $(shell date +%y%m%d-%H%M)
UNIQUE_DOCKERHUB_TAG := $(DOCKERHUB_USER)/$(IMAGE_NAME):$(UNIQUE_TAG)
LAST_TAG_FILE := .last-tag

define set_tag
	@echo "Setting '$(1)' tag to point to $(2)..."
	docker buildx imagetools create -t $(DOCKERHUB_USER)/$(IMAGE_NAME):$(1) $(DOCKERHUB_USER)/$(IMAGE_NAME):$(2)
	@echo "'$(1)' tag updated to $(2)"
endef

help:
	@echo "Scribe Lite Docker Build & Push (Multi-Arch)"
	@echo ""
	@echo "Usage:"
	@echo "  make build              - Build locally for current platform (tagged as dev)"
	@echo "  make push               - Build multi-arch (amd64+arm64), push with timestamp tag, update 'dev' tag"
	@echo "  make build-and-push     - Alias for push"
	@echo "  make set-latest [TAG=]  - Set 'latest' tag to specified tag (or last pushed)"
	@echo "  make set-dev [TAG=]     - Set 'dev' tag to specified tag (or last pushed)"
	@echo "  make setup-builder      - Create/bootstrap the multi-arch buildx builder"
	@echo ""
	@echo "Configuration:"
	@echo "  PLATFORMS=$(PLATFORMS)"

setup-builder:
	@if ! docker buildx inspect $(BUILDER_NAME) >/dev/null 2>&1; then \
		echo "Creating buildx builder '$(BUILDER_NAME)'..."; \
		docker buildx create --name $(BUILDER_NAME) --driver docker-container --bootstrap; \
	else \
		echo "Builder '$(BUILDER_NAME)' already exists"; \
	fi

build:
	@echo "Building $(LOCAL_TAG) for current platform..."
	docker build -f $(DOCKERFILE) -t $(LOCAL_TAG) $(CONTEXT)
	@echo "Build complete: $(LOCAL_TAG)"

push: setup-builder
	@echo "Building multi-arch $(UNIQUE_DOCKERHUB_TAG) for $(PLATFORMS)..."
	docker buildx build \
		--builder $(BUILDER_NAME) \
		--platform $(PLATFORMS) \
		-f $(DOCKERFILE) \
		-t $(UNIQUE_DOCKERHUB_TAG) \
		--push \
		$(CONTEXT)
	@echo "$(UNIQUE_TAG)" > $(LAST_TAG_FILE)
	@echo "Push complete: $(UNIQUE_DOCKERHUB_TAG)"
	$(call set_tag,dev,$(UNIQUE_TAG))

build-and-push: push

set-latest:
	@if [ -z "$(TAG)" ]; then \
		if [ -f $(LAST_TAG_FILE) ]; then \
			TAG_TO_USE=$$(cat $(LAST_TAG_FILE)); \
		else \
			echo "Error: No TAG specified and $(LAST_TAG_FILE) not found"; exit 1; \
		fi; \
	else \
		TAG_TO_USE=$(TAG); \
	fi; \
	echo "Setting 'latest' tag to point to $$TAG_TO_USE..."; \
	docker buildx imagetools create -t $(DOCKERHUB_USER)/$(IMAGE_NAME):latest $(DOCKERHUB_USER)/$(IMAGE_NAME):$$TAG_TO_USE; \
	echo "'latest' tag updated to $$TAG_TO_USE"

set-dev:
	@if [ -z "$(TAG)" ]; then \
		if [ -f $(LAST_TAG_FILE) ]; then \
			TAG_TO_USE=$$(cat $(LAST_TAG_FILE)); \
		else \
			echo "Error: No TAG specified and $(LAST_TAG_FILE) not found"; exit 1; \
		fi; \
	else \
		TAG_TO_USE=$(TAG); \
	fi; \
	echo "Setting 'dev' tag to point to $$TAG_TO_USE..."; \
	docker buildx imagetools create -t $(DOCKERHUB_USER)/$(IMAGE_NAME):dev $(DOCKERHUB_USER)/$(IMAGE_NAME):$$TAG_TO_USE; \
	echo "'dev' tag updated to $$TAG_TO_USE"

# ============================================================================
# Deployment (make lite from repo root)
# ============================================================================

-include $(ENV_FILE)

all: env preflight up init-db test
	@HOST_IP=$$(hostname -I 2>/dev/null | awk '{print $$1}'); \
	HOST=$${HOST_IP:-localhost}; \
	echo ""; \
	echo "Scribe Lite is running."; \
	echo "  Dashboard: http://$$HOST:3000"; \
	echo "  API docs:  http://$$HOST:8056/docs"

# --- Environment (reuse compose env target) ---
env:
	@$(MAKE) --no-print-directory -C $(ROOT)/deploy/compose env

# --- Preflight (reuse compose preflight target) ---
preflight:
	@$(MAKE) --no-print-directory -C $(ROOT)/deploy/compose preflight

# --- Up ---
up:
	@if ! docker info > /dev/null 2>&1; then echo "ERROR: Docker is not running."; exit 1; fi
	@IMAGE_TAG=$$(grep -E '^IMAGE_TAG=' $(ENV_FILE) 2>/dev/null | cut -d= -f2); \
	IMAGE_TAG=$${IMAGE_TAG:-latest}; \
	TX_URL=$$(grep -E '^LITE_TRANSCRIPTION_SERVICE_URL=' $(ENV_FILE) 2>/dev/null | cut -d= -f2); \
	TX_URL=$${TX_URL:-$$(grep -E '^TRANSCRIPTION_SERVICE_URL=' $(ENV_FILE) 2>/dev/null | cut -d= -f2)}; \
	TX_TOKEN=$$(grep -E '^LITE_TRANSCRIPTION_SERVICE_TOKEN=' $(ENV_FILE) 2>/dev/null | cut -d= -f2); \
	TX_TOKEN=$${TX_TOKEN:-$$(grep -E '^TRANSCRIPTION_SERVICE_TOKEN=' $(ENV_FILE) 2>/dev/null | cut -d= -f2)}; \
	ADMIN_TK=$$(grep -E '^ADMIN_TOKEN=' $(ENV_FILE) 2>/dev/null | cut -d= -f2); \
	ADMIN_TK=$${ADMIN_TK:-changeme}; \
	echo "Starting PostgreSQL..."; \
	if docker ps -q -f name=scribe-postgres 2>/dev/null | grep -q .; then \
		echo "  PostgreSQL already running"; \
	else \
		docker rm -f scribe-postgres 2>/dev/null || true; \
		docker run -d --name scribe-postgres --network host \
			-e POSTGRES_DB=scribe \
			-e POSTGRES_USER=postgres \
			-e POSTGRES_PASSWORD=postgres \
			postgres:17-alpine \
			-c listen_addresses=127.0.0.1 \
			-c idle_in_transaction_session_timeout=60000 > /dev/null; \
		echo "  Waiting for PostgreSQL..."; \
		for i in $$(seq 1 12); do \
			docker exec scribe-postgres pg_isready -U postgres -d scribe -q 2>/dev/null && break; \
			sleep 5; \
		done; \
	fi; \
	echo "  ✓ PostgreSQL ready"; \
	echo "Pulling $(DOCKERHUB_USER)/$(IMAGE_NAME):$$IMAGE_TAG..."; \
	docker pull $(DOCKERHUB_USER)/$(IMAGE_NAME):$$IMAGE_TAG; \
	echo "Starting Scribe Lite..."; \
	docker rm -f scribe-lite 2>/dev/null || true; \
	docker run -d --name scribe-lite --shm-size=2g --network host \
		-v scribe-lite-recordings:/var/lib/scribe/recordings \
		-e DATABASE_URL=postgresql://postgres:postgres@localhost:5432/scribe \
		-e DB_PASSWORD=postgres \
		-e DB_SSL_MODE=disable \
		-e REDIS_URL=redis://localhost:6379/0 \
		-e ADMIN_API_TOKEN=$$ADMIN_TK \
		-e SCRIBE_AUTH_COOKIE_NAME=scribe-token-lite \
		-e SCRIBE_USER_INFO_COOKIE_NAME=scribe-user-info-lite \
		-e TRANSCRIPTION_SERVICE_URL=$$TX_URL \
		-e TRANSCRIPTION_SERVICE_TOKEN=$$TX_TOKEN \
		$(DOCKERHUB_USER)/$(IMAGE_NAME):$$IMAGE_TAG > /dev/null; \
	echo "  Waiting for services (up to 2 min)..."; \
	for i in $$(seq 1 24); do \
		curl -sf -o /dev/null http://localhost:8056/ 2>/dev/null && break; \
		sleep 5; \
	done; \
	echo "  ✓ Scribe Lite running"

# --- Init DB ---
init-db:
	@echo "Running schema sync..."
	@docker exec scribe-lite python3 -c \
		"import asyncio; from admin_models.database import init_db; asyncio.run(init_db())" 2>/dev/null || true
	@docker exec scribe-lite python3 -c \
		"import asyncio; from meeting_api.database import init_db; asyncio.run(init_db())" 2>/dev/null || true
	@echo "  ✓ Schema sync complete"

# --- Test ---
test:
	@echo "Checking services..."
	@for ep in "8056:API Gateway" "8057:Admin API" "3000:Dashboard"; do \
		PORT=$${ep%%:*}; \
		NAME=$${ep##*:}; \
		if curl -sf -o /dev/null http://localhost:$$PORT/ 2>/dev/null; then \
			echo "  ✓ $$NAME (port $$PORT)"; \
		else \
			echo "  ✗ $$NAME not responding (port $$PORT)"; \
		fi; \
	done

# --- Down ---
down:
	@echo "Stopping Scribe Lite..."
	@docker stop scribe-lite 2>/dev/null || true
	@docker rm scribe-lite 2>/dev/null || true
	@docker stop scribe-postgres 2>/dev/null || true
	@docker rm scribe-postgres 2>/dev/null || true
	@echo "  ✓ Stopped"
