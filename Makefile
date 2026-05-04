CRYSTAL_COMPILER := crystal
C_COMPILER := gcc
CFLAGS := -O3 -fPIC
SOURCE_DIR := src
BUILD_DIR := build
BIN_DIR := bin
EXT_DIR = $(SOURCE_DIR)/ext
LIB_DIR := lib

# OS Detection
ifeq ($(OS),Windows_NT)
	OBJ_EXT = .obj
	RM = del /Q
	MKDIR = mkdir
else
	OBJ_EXT = .o
	RM = rm -rf
	MKDIR = mkdir -p
endif

# Get all sdl3 and sdl3-mixer flags automatically
SDL_FLAGS := $(shell pkg-config --libs sdl3-mixer)

# Your local stb_truetype object
STB_TRUETYPE_SRC := $(EXT_DIR)/stb_truetype
STB_TRUETYPE_OBJ := $(BUILD_DIR)/stb_truetype$(OBJ_EXT)

# Combine them for Crystal
LINKFLAGS := $(SDL_FLAGS) $(abspath $(STB_TRUETYPE_OBJ))

# File targets
SOURCES := $(shell find $(SOURCE_DIR) -name "*.cr")

# Phony targets don't represent files
.PHONY: default clean build run

# The default target, executed when you just run `make`
default: run

clean:
	@echo "Executing clean..."
	$(RM) $(BUILD_DIR)

$(STB_TRUETYPE_OBJ): $(STB_TRUETYPE_SRC).c $(STB_TRUETYPE_SRC).h
	@${MKDIR} $(BUILD_DIR)
	@echo "Building stb_truetype..."
	$(C_COMPILER) $(CFLAGS) -c $< -o $@

build: $(STB_TRUETYPE_OBJ) $(SOURCES)
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "Error: You must provide EXAMPLE=name"; \
		exit 1; \
	fi
	@${MKDIR} $(BUILD_DIR)
	@echo "Building example: $(EXAMPLE)..."
	$(CRYSTAL_COMPILER) build examples/$(EXAMPLE).cr -o $(BUILD_DIR)/$(EXAMPLE) --link-flags "$(LINKFLAGS)" -p

run: build
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "Error: You must provide EXAMPLE=name"; \
		exit 1; \
	fi
	@echo "Running example: $(EXAMPLE)..."
	./$(BUILD_DIR)/$(EXAMPLE)
