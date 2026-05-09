CRYSTAL_COMPILER := crystal
C_COMPILER := gcc
CFLAGS := -O3 -fPIC
SOURCE_DIR := src
BUILD_DIR := build
BIN_DIR := bin
EXT_DIR = $(SOURCE_DIR)/ext
LIB_DIR := lib
OBJ_EXT = .o
RM = rm -rf
MKDIR = mkdir -p

# Get all sdl3 and sdl3-mixer flags automatically
ifeq ($(OS),Windows_NT)
	SDL_FLAGS :=
else
	SDL_FLAGS := $(shell pkg-config --libs sdl3-mixer)
endif

# Your local stb_truetype object
STB_TRUETYPE_SRC := $(EXT_DIR)/stb_truetype
STB_TRUETYPE_OBJ := $(BUILD_DIR)/stb_truetype$(OBJ_EXT)

# Combine them for unix
ifeq ($(OS),Windows_NT)
	LINKFLAGS := $(abspath $(STB_TRUETYPE_OBJ)) /NODEFAULTLIB:libcmt.lib
else
	LINKFLAGS := $(SDL_FLAGS) $(abspath $(STB_TRUETYPE_OBJ))
endif

# File targets
SOURCES := $(shell find $(SOURCE_DIR) -name "*.cr")

# Windows cl.exe loading env
VCVARS = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community\\VC\\Auxiliary\\Build\\vcvars64.bat"

# Phony targets don't represent files
.PHONY: default clean build run

# The default target, executed when you just run `make`
default: run

clean:
	@echo "Executing clean..."
	$(RM) $(BUILD_DIR)

$(STB_TRUETYPE_OBJ): $(STB_TRUETYPE_SRC).c $(STB_TRUETYPE_SRC).h
	@echo "Building stb_truetype..."
	@${MKDIR} $(BUILD_DIR)
ifeq ($(OS),Windows_NT)
	msvc_env.bat /O2 /c $< /Fo:$@
else
	$(C_COMPILER) $(CFLAGS) -c $< -o $@
endif

build: $(STB_TRUETYPE_OBJ) $(SOURCES)
	@if [ -z "$(EXAMPLE)" ]; then \
		@echo "Error: You must provide EXAMPLE=name"; \
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
