# The default target, executed when you just run `make`
default: run

GSDL_ROOT := .

include gsdl.mk

CRYSTAL_COMPILER := crystal
C_COMPILER := gcc
CFLAGS := -O3 -fPIC
SOURCE_DIR := src
BUILD_DIR := build
BIN_DIR := bin
LIB_DIR := lib
OBJ_EXT = .o
RM = rm -rf
MKDIR = mkdir -p

# File targets
SOURCES := $(STB_TRUETYPE_OBJ) $(shell find $(SOURCE_DIR) -name "*.cr")

# Phony targets don't represent files
.PHONY: default clean build run

clean:
	@echo "Executing clean..."
	$(RM) $(BUILD_DIR)

build: $(SOURCES)
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "Error: You must provide EXAMPLE=name"; \
		exit 1; \
	fi
	@${MKDIR} $(BUILD_DIR)
	@echo "Building example: $(EXAMPLE)..."
	$(CRYSTAL_COMPILER) build examples/$(EXAMPLE).cr -o $(BUILD_DIR)/$(subst /,_,$(EXAMPLE)) --link-flags "$(GSDL_LINK_FLAGS)" -p

run: build
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "Error: You must provide EXAMPLE=name"; \
		exit 1; \
	fi
	@echo "Running example: $(EXAMPLE)..."
	./$(BUILD_DIR)/$(subst /,_,$(EXAMPLE))
