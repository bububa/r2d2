GOCMD=go
GOTEST=$(GOCMD) test
GOVET=$(GOCMD) vet
BINARY_NAME=r2d2

export BUILD_TYPE?=
export STABLE_BUILD_TYPE?=$(BUILD_TYPE)
export CMAKE_ARGS?=
CGO_LDFLAGS?=
CUDA_LIBPATH?=/usr/local/cuda/lib64/
GO_TAGS?=
BUILD_ID?=git

BACKEND_DIR=pkg/backend
BACKEND_LLM_DIR=$(BACKEND_DIR)/llm

VERSION?=$(shell git describe --always --tags || echo "dev" )
# go tool nm ./local-ai | grep Commit
LD_FLAGS?=
override LD_FLAGS += -X "github.com/bububa/r2d2/internal.Version=$(VERSION)"
override LD_FLAGS += -X "github.com/bububa/r2d2/internal.Commit=$(shell git rev-parse HEAD)"

OPTIONAL_TARGETS?=
ESPEAK_DATA?=

OS := $(shell uname -s)
ARCH := $(shell uname -m)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

ifndef UNAME_S
UNAME_S := $(shell uname -s)
endif

ifeq ($(UNAME_S),Darwin)
	CGO_LDFLAGS += -lcblas -framework Accelerate
ifneq ($(BUILD_TYPE),metal)
    # explicit disable metal if on Darwin and metal is disabled
	CMAKE_ARGS+=-DLLAMA_METAL=OFF
endif
endif

ifeq ($(BUILD_TYPE),openblas)
	CGO_LDFLAGS+=-lopenblas
endif

ifeq ($(BUILD_TYPE),cublas)
	CGO_LDFLAGS+=-lcublas -lcudart -L$(CUDA_LIBPATH)
	export LLAMA_CUBLAS=1
endif

ifeq ($(BUILD_TYPE),hipblas)
	ROCM_HOME ?= /opt/rocm
	export CXX=$(ROCM_HOME)/llvm/bin/clang++
	export CC=$(ROCM_HOME)/llvm/bin/clang
	# Llama-stable has no hipblas support, so override it here.
	export STABLE_BUILD_TYPE=
	GPU_TARGETS ?= gfx900,gfx90a,gfx1030,gfx1031,gfx1100
	AMDGPU_TARGETS ?= "$(GPU_TARGETS)"
	CMAKE_ARGS+=-DLLAMA_HIPBLAS=ON -DAMDGPU_TARGETS="$(AMDGPU_TARGETS)" -DGPU_TARGETS="$(GPU_TARGETS)"
	CGO_LDFLAGS += -O3 --rtlib=compiler-rt -unwindlib=libgcc -lhipblas -lrocblas --hip-link
endif

ifeq ($(BUILD_TYPE),metal)
	CGO_LDFLAGS+=-framework Foundation -framework Metal -framework MetalKit -framework MetalPerformanceShaders
	export LLAMA_METAL=1
endif

ifeq ($(BUILD_TYPE),clblas)
	CGO_LDFLAGS+=-lOpenCL -lclblast
endif

# glibc-static or glibc-devel-static required
ifeq ($(STATIC),true)
	LD_FLAGS=-linkmode external -extldflags -static
endif

ifeq ($(findstring stablediffusion,$(GO_TAGS)),stablediffusion)
#	OPTIONAL_TARGETS+=go-stable-diffusion/libstablediffusion.a
	OPTIONAL_GRPC+=backend-assets/grpc/stablediffusion
endif

ifeq ($(findstring tts,$(GO_TAGS)),tts)
#	OPTIONAL_TARGETS+=go-piper/libpiper_binding.a
#	OPTIONAL_TARGETS+=backend-assets/espeak-ng-data
	OPTIONAL_GRPC+=backend-assets/grpc/piper
endif

GRPC_BACKENDS?=backend-assets/grpc/langchain-huggingface backend-assets/grpc/falcon-ggml backend-assets/grpc/bert-embeddings backend-assets/grpc/falcon backend-assets/grpc/bloomz backend-assets/grpc/llama backend-assets/grpc/llama-stable backend-assets/grpc/gpt4all backend-assets/grpc/dolly backend-assets/grpc/gpt2 backend-assets/grpc/gptj backend-assets/grpc/gptneox backend-assets/grpc/mpt backend-assets/grpc/replit backend-assets/grpc/starcoder backend-assets/grpc/rwkv backend-assets/grpc/whisper $(OPTIONAL_GRPC)

.PHONY: all test build prepare

all: help

update/submodules:
	git submodule update --init --recursive --depth 2

gomod/replace:
	$(GOCMD) mod edit -replace github.com/go-skynet/go-llama.cpp=$(shell pwd)/$(BACKEND_LLM_DIR)/llama

libggllm: 
	cd $(BACKEND_LLM_DIR) && $(MAKE) -C ggllm BUILD_TYPE=$(BUILD_TYPE) libggllm.a

libllama: 
	cd $(BACKEND_LLM_DIR) && $(MAKE) -C llama BUILD_TYPE=$(BUILD_TYPE) libbinding.a

prepare: update/submodules gomod/replace libggllm libllama


## GENERIC
clean: ## Rebuilds the project
	$(GOCMD) clean -cache
	$(MAKE) -C $(BACKEND_LLM_DIR)/llama clean
	$(MAKE) -C $(BACKEND_LLM_DIR)/ggllm clean
	#$(MAKE) -C gpt4all/gpt4all-bindings/golang/ clean
	#$(MAKE) -C go-ggml-transformers clean
	#$(MAKE) -C go-rwkv clean
	#$(MAKE) -C whisper.cpp clean
	#$(MAKE) -C go-stable-diffusion clean
	#$(MAKE) -C go-bert clean
	#$(MAKE) -C bloomz clean
	#$(MAKE) -C go-piper clean
	#$(MAKE) build

## Build:

build: grpcs prepare ## Build the project
	$(info ${GREEN}I r2d2 build info:${RESET})
	$(info ${GREEN}I BUILD_TYPE: ${YELLOW}$(BUILD_TYPE)${RESET})
	$(info ${GREEN}I GO_TAGS: ${YELLOW}$(GO_TAGS)${RESET})
	$(info ${GREEN}I LD_FLAGS: ${YELLOW}$(LD_FLAGS)${RESET})

	CGO_LDFLAGS="$(CGO_LDFLAGS)" $(GOCMD) build -ldflags "$(LD_FLAGS)" -tags "$(GO_TAGS)" -o $(BINARY_NAME) ./

dist: build
	mkdir -p release
	cp $(BINARY_NAME) release/$(BINARY_NAME)-$(BUILD_ID)-$(OS)-$(ARCH)
