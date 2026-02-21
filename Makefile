CRYSTAL_COMPILER := crystal
SOURCE_DIR := src
BUILD_DIR := build
LIB_DIR := lib
SDL3_MIXER_LIB_DIR := /Users/matt/ext_libs/sdl3_mixer/lib
LINKFLAGS := -L$(SDL3_MIXER_LIB_DIR) -Wl,-rpath,$(SDL3_MIXER_LIB_DIR)
# SDL3_IMAGE_LIB_PATH := /opt/homebrew/Cellar/sdl3_image/3.4.0/lib
# SDL3_TTF_LIB_PATH := /opt/homebrew/Cellar/sdl3_ttf/3.2.2/lib
LIB_NAME := libsdl3.a
RM_CMD := rm -rf
MKDIR_CMD := mkdir -p

# Phony targets don't represent files
.PHONY: default clean examples build run packer run-release

# The default target, executed when you just run `make`
default:

clean:
	@echo "Executing clean..."
	$(RM_CMD) $(BUILD_DIR)
	$(RM_CMD) $(LIB_DIR)

packer:
	@echo "Building packer tool..."
	$(MKDIR_CMD) $(BUILD_DIR)
	$(CRYSTAL_COMPILER) build $(SOURCE_DIR)/packer.cr -o gsdl-packer --release --no-debug

examples:
	@echo "Building and running all examples..."
	@$(MAKE) run EXAMPLE=text
	@$(MAKE) run EXAMPLE=shapes
	@$(MAKE) run EXAMPLE=sprite
	@$(MAKE) run EXAMPLE=animation
	@$(MAKE) run EXAMPLE=audio
	@$(MAKE) run EXAMPLE=keys
	@$(MAKE) run EXAMPLE=mouse
	@$(MAKE) run EXAMPLE=game_pad
	@$(MAKE) run EXAMPLE=collision
	@$(MAKE) run EXAMPLE=tile_map
	@$(MAKE) run EXAMPLE=platformer
	@$(MAKE) run EXAMPLE=message
	@$(MAKE) run EXAMPLE=menu
	@$(MAKE) run EXAMPLE=switch_scene
	@$(MAKE) run EXAMPLE=logical_presentation

build:
	@echo "Building example: $(EXAMPLE)"
	$(MKDIR_CMD) $(BUILD_DIR)
	$(CRYSTAL_COMPILER) build examples/$(EXAMPLE).cr -o $(BUILD_DIR)/$(EXAMPLE) --link-flags "$(LINKFLAGS)" --no-debug

run: build
	@echo "Running example: $(EXAMPLE)"
	./$(BUILD_DIR)/$(EXAMPLE)

run-release:
	@echo "Building and running example: $(EXAMPLE)"
	$(MKDIR_CMD) $(BUILD_DIR)
	$(CRYSTAL_COMPILER) build examples/$(EXAMPLE).cr -o $(BUILD_DIR)/$(EXAMPLE) --release --link-flags "$(LINKFLAGS)" --no-debug
	./$(BUILD_DIR)/$(EXAMPLE)

debug:
	@echo "Building and running example in debug mode: $(EXAMPLE)"
	$(MKDIR_CMD) $(BUILD_DIR)
	$(CRYSTAL_COMPILER) build examples/$(EXAMPLE).cr -o $(BUILD_DIR)/$(EXAMPLE)_debug --link-flags "$(LINKFLAGS)" --error-trace
	./$(BUILD_DIR)/$(EXAMPLE)_debug
