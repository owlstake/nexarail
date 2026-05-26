#!/usr/bin/make -f

PROJECT_NAME    := nexarail
BINARY          := nexaraild
BINARY_LINUX    := nexaraild-linux
BUILD_DIR       := ./build
COMMIT          := $(shell git log -1 --format='%H' 2>/dev/null || echo "dev")
VERSION         := 0.1.0-dev

LD_FLAGS := \
	-X github.com/cosmos/cosmos-sdk/version.Name=$(PROJECT_NAME) \
	-X github.com/cosmos/cosmos-sdk/version.AppName=$(BINARY) \
	-X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
	-X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT) \
	-X github.com/cosmos/cosmos-sdk/version.BuildTags=''

all: build

.PHONY: build build-linux clean install init-devnet test

build: go.sum
	@echo "Building $(BINARY)..."
	go build -mod=readonly -ldflags '$(LD_FLAGS)' -o $(BUILD_DIR)/$(BINARY) ./cmd/$(BINARY)
	@echo "Binary built: $(BUILD_DIR)/$(BINARY)"

build-linux: go.sum
	@echo "Building $(BINARY_LINUX)..."
	GOOS=linux GOARCH=amd64 go build -mod=readonly -ldflags '$(LD_FLAGS)' -o $(BUILD_DIR)/$(BINARY_LINUX) ./cmd/$(BINARY)
	@echo "Binary built: $(BUILD_DIR)/$(BINARY_LINUX)"

install: go.sum
	@echo "Installing $(BINARY)..."
	go install -mod=readonly -ldflags '$(LD_FLAGS)' ./cmd/$(BINARY)
	@echo "Installed: $(shell which $(BINARY) 2>/dev/null || echo 'check GOPATH/bin')"

clean:
	rm -rf $(BUILD_DIR)/*
	rm -rf ~/.nexarail/

init-devnet: build
	@echo "Initializing NexaRail devnet..."
	@bash scripts/init-devnet.sh

start-devnet: build
	@echo "Starting NexaRail devnet..."
	@bash scripts/start-devnet.sh

reset-devnet:
	@echo "Resetting NexaRail devnet..."
	rm -rf ~/.nexarail/

test:
	@echo "Running tests..."
	go test ./... -v -count=1

test-short:
	@echo "Running short tests..."
	go test ./... -v -count=1 -short

go.sum: go.mod
	@echo "Ensuring dependencies..."
	go mod tidy

.PHONY: docker-build docker-start

docker-build:
	@echo "Building Docker image..."
	docker build -t $(PROJECT_NAME):latest -f scripts/docker/Dockerfile .

docker-start:
	@echo "Starting Docker devnet..."
	docker compose -f scripts/docker/docker-compose.yml up -d

docker-stop:
	@echo "Stopping Docker devnet..."
	docker compose -f scripts/docker/docker-compose.yml down

docker-logs:
	docker compose -f scripts/docker/docker-compose.yml logs -f
