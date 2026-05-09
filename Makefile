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
  LINKFLAGS := /NODEFAULTLIB:libcmt.lib
else
  LINKFLAGS := $(shell pkg-config --libs sdl3-mixer)
endif

STB_TRUETYPE_SRC := $(EXT_DIR)/stb_truetype

# File targets
SOURCES := $(shell find $(SOURCE_DIR) -name "*.cr")

# Phony targets don't represent files
.PHONY: default clean build run build_win_stb_truetype

# The default target, executed when you just run `make`
default: run

clean:
	@echo "Executing clean..."
	$(RM) $(BUILD_DIR)

build_win_stb_truetype: $(STB_TRUETYPE_SRC).c $(STB_TRUETYPE_SRC).h
	@echo "Building windows stb_truetype..."
	msvc_env.bat /O2 /c $< /Fo:$(EXT_DIR)/stb_truetype_win_x64.obj
	@echo "Built windows $(EXT_DIR)/stb_truetype_win_x64.obj"

ifeq ($(OS),Windows_NT)
  # Use the pre-compiled object on Windows
  STB_TRUETYPE_OBJ = $(EXT_DIR)/stb_truetype_win_x64.obj
else
  # Compile from source on Linux/macOS
  STB_TRUETYPE_OBJ = build/stb_truetype.o
  $(STB_TRUETYPE_OBJ): $(STB_TRUETYPE_SRC).c $(STB_TRUETYPE_SRC).h
	mkdir -p build
	$(CC) -O3 -fPIC -c $< -o $@
endif

build: $(SOURCES)
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
