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
EXT_DIR = $(SOURCE_DIR)/ext
STB_TRUETYPE_SRC = $(EXT_DIR)/stb_truetype
LIB_DIR := lib
OBJ_EXT = .o
RM = rm -rf
MKDIR = mkdir -p

# File targets
SOURCES := $(GSDL_STB_TRUETYPE_OBJ) $(shell find $(SOURCE_DIR) -name "*.cr")

# Phony targets don't represent files
.PHONY: default clean build run build_win_stb_truetype

clean:
	@echo "Executing clean..."
	$(RM) $(BUILD_DIR)

build_win_stb_truetype: $(STB_TRUETYPE_SRC).c $(STB_TRUETYPE_SRC).h
	@echo "Building windows stb_truetype..."
	msvc_env.bat /O2 /c $< /Fo:$(EXT_DIR)/$(STB_TRUETYPE_SRC)_win_x64.obj
	@echo "Built windows $(EXT_DIR)/$(STB_TRUETYPE_SRC)_win_x64.obj"

build: $(SOURCES)
	@if [ -z "$(EXAMPLE)" ]; then \
		@echo "Error: You must provide EXAMPLE=name"; \
		exit 1; \
	fi
	@${MKDIR} $(BUILD_DIR)
	@echo "Building example: $(EXAMPLE)..."
	$(CRYSTAL_COMPILER) build examples/$(EXAMPLE).cr -o $(BUILD_DIR)/$(EXAMPLE) --link-flags "$(GSDL_LINK_FLAGS)" -p

run: build
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "Error: You must provide EXAMPLE=name"; \
		exit 1; \
	fi
	@echo "Running example: $(EXAMPLE)..."
	./$(BUILD_DIR)/$(EXAMPLE)
