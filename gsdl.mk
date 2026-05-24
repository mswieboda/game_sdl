ifeq ($(OS),Windows_NT)
  # Windows link flags (if any extra are needed beyond the .obj)
  GSDL_LINK_FLAGS := /NODEFAULTLIB:libcmt.lib
else
	# SDL3 Detection (Unix-specific)
  # Automatically grab SDL3 flags if pkg-config is available
  # Otherwise, fallback to standard Homebrew/Linux paths
  GSDL_ROOT ?= lib/game_sdl
  SDL3_FLAGS := $(shell pkg-config --libs sdl3 sdl3-mixer sdl3-image sdl3-ttf 2>/dev/null || echo "-lSDL3 -lSDL3_mixer -lSDL3_image -lSDL3_ttf")
  GSDL_LINK_FLAGS := $(SDL3_FLAGS)
endif

STB_TRUETYPE_DIR ?= lib/stb_truetype
-include $(STB_TRUETYPE_DIR)/stb_truetype.mk
