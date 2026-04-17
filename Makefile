CRYSTAL_COMPILER := crystal
SOURCE_DIR := src
BUILD_DIR := build
BIN_DIR := bin
LIB_DIR := lib
SDL3_MIXER_LIB_DIR := /usr/local/lib
LINKFLAGS := -L$(SDL3_MIXER_LIB_DIR) -Wl,-rpath,$(SDL3_MIXER_LIB_DIR)
RM_CMD := rm -rf
MKDIR_CMD := mkdir -p
PACKER_FILE := build/assets.pack
PACKER_BIN := bin/gsdl-packer
SRC := examples/$(EXAMPLE).cr

# File targets
DEBUG_BIN := $(BUILD_DIR)/$(EXAMPLE)_debug
RELEASE_BIN := $(BUILD_DIR)/$(EXAMPLE)
SOURCES := $(shell find $(SOURCE_DIR) -name "*.cr")

# Phony targets don't represent files
.PHONY: default clean examples examples_full build_examples_full build run packer pack run-release debug re release-package release-package-mac release-package-win release-package-linux

# The default target, executed when you just run `make`
default: run

re:
	@$(MAKE) -B run

release-package:
	@echo "Creating release package for example: $(EXAMPLE) target: $(TARGET)"
	$(MKDIR_CMD) $(BUILD_DIR)
	crystal run src/gsdl/release_helper.cr -- \
		--game=$(EXAMPLE) \
		--target=$(TARGET) \
		$(if $(SRC),--src="$(SRC)") \
		$(if $(APP_NAME),--name="$(APP_NAME)") \
		$(if $(VERSION),--version=$(VERSION)) \
		$(if $(ICON),--icon=$(ICON)) \
		$(if $(BUNDLE_ID),--bundle-id=$(BUNDLE_ID)) \
		$(if $(OUTPUT),--output=$(OUTPUT))

release-package-mac: TARGET := mac
release-package-mac: release-package

release-package-win: TARGET := win
release-package-win: release-package

release-package-linux: TARGET := linux
release-package-linux: release-package

clean:
	@echo "Executing clean..."
	$(RM_CMD) $(BUILD_DIR)
	$(RM_CMD) $(LIB_DIR)

$(PACKER_BIN): $(SOURCES)
	@echo "Building packer tool..."
	$(MKDIR_CMD) $(BIN_DIR)
	$(CRYSTAL_COMPILER) build $(SOURCE_DIR)/packer.cr -o $(BIN_DIR)/gsdl-packer --release --no-debug -p

packer: $(PACKER_BIN)

$(PACKER_FILE): $(PACKER_BIN)
	@echo "Packing assets via GameSDL packer..."
	./$(PACKER_BIN)

pack: $(PACKER_FILE)

examples:
	@echo "Building and running all examples..."
	@$(MAKE) run EXAMPLE=full || exit 1
	@$(MAKE) run EXAMPLE=text || exit 1
	@$(MAKE) run EXAMPLE=shapes || exit 1
	@$(MAKE) run EXAMPLE=sprite || exit 1
	@$(MAKE) run EXAMPLE=animation || exit 1
	@$(MAKE) run EXAMPLE=audio || exit 1
	@$(MAKE) run EXAMPLE=keys || exit 1
	@$(MAKE) run EXAMPLE=mouse || exit 1
	@$(MAKE) run EXAMPLE=game_pad || exit 1
	@$(MAKE) run EXAMPLE=collision || exit 1
	@$(MAKE) run EXAMPLE=tile_map_data || exit 1
	@$(MAKE) run EXAMPLE=tile_map_layers || exit 1
	@$(MAKE) run EXAMPLE=platformer || exit 1
	@$(MAKE) run EXAMPLE=message || exit 1
	@$(MAKE) run EXAMPLE=tween || exit 1
	@$(MAKE) run EXAMPLE=menu || exit 1
	@$(MAKE) run EXAMPLE=scene_switch || exit 1
	@$(MAKE) run EXAMPLE=logical_presentation || exit 1
	@$(MAKE) run EXAMPLE=shoot_em_up_movement || exit 1

examples_full:
	@echo "Building and running all examples in folder..."
	@started=0; \
	for f in examples/*.cr; do \
		name=$$(basename $$f .cr); \
		if [ -n "$(START)" ]; then \
			if [ "$$name" = "$(START)" ]; then started=1; fi; \
			if [ $$started -eq 0 ]; then continue; fi; \
		fi; \
		$(MAKE) run EXAMPLE=$$name || exit 1; \
	done

build_examples_full:
	@echo "Building all examples in folder..."
	@started=0; \
	for f in examples/*.cr; do \
		name=$$(basename $$f .cr); \
		if [ -n "$(START)" ]; then \
			if [ "$$name" = "$(START)" ]; then started=1; fi; \
			if [ $$started -eq 0 ]; then continue; fi; \
		fi; \
		printf "Building $$name... "; \
		$(CRYSTAL_COMPILER) build $$f -o /dev/null --link-flags "$(LINKFLAGS)" --no-debug -p > /dev/null 2>&1 && echo "OK" || (echo "FAILED"; $(MAKE) build EXAMPLE=$$name; exit 1); \
	done; \
	echo "All examples compiled successfully!"

$(RELEASE_BIN): examples/$(EXAMPLE).cr $(SOURCES)
	@echo "Building example: $(EXAMPLE)"
	$(MKDIR_CMD) $(BUILD_DIR)
	$(CRYSTAL_COMPILER) build examples/$(EXAMPLE).cr -o $(RELEASE_BIN) --link-flags "$(LINKFLAGS)" --no-debug -p

build: $(RELEASE_BIN)

run: build
	@echo "Running example: $(EXAMPLE)"
	./$(RELEASE_BIN)

$(BUILD_DIR)/$(EXAMPLE)_release: examples/$(EXAMPLE).cr $(SOURCES)
	@echo "Building release example: $(EXAMPLE)"
	$(MKDIR_CMD) $(BUILD_DIR)
	$(CRYSTAL_COMPILER) build examples/$(EXAMPLE).cr -o $@ --release --link-flags "$(LINKFLAGS)" --no-debug -p

run-release: $(BUILD_DIR)/$(EXAMPLE)_release
	@echo "Running release example: $(EXAMPLE)"
	./$(BUILD_DIR)/$(EXAMPLE)_release

$(DEBUG_BIN): examples/$(EXAMPLE).cr $(SOURCES)
	@echo "Building example in debug mode: $(EXAMPLE)"
	$(MKDIR_CMD) $(BUILD_DIR)
	$(CRYSTAL_COMPILER) build examples/$(EXAMPLE).cr -o $(DEBUG_BIN) --link-flags "$(LINKFLAGS)" --error-trace -p

debug: $(DEBUG_BIN)
	@echo "Running example in debug mode: $(EXAMPLE)"
	./$(DEBUG_BIN)
