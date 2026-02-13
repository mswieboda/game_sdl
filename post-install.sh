#!/bin/sh
# This script is executed after the 'game_sdl' shard is installed.
# It copies the pre-compiled 'gsdl-packer' tool into the main
# project's ./bin directory for easy access.

set -e

# The root of the consuming project where `shards install` was run
PROJECT_ROOT=$(pwd)

# The path to the tool inside the installed shard directory
SHARD_TOOL_PATH="$PROJECT_ROOT/lib/game_sdl/gsdl-packer"

# The target directory in the consuming project
TARGET_DIR="$PROJECT_ROOT/bin"

# The final path for the tool in the consuming project
TARGET_TOOL_PATH="$TARGET_DIR/gsdl-packer"

echo "GSDL: Installing packer tool..."

if [ ! -f "$SHARD_TOOL_PATH" ]; then
  echo "GSDL: ERROR - Pre-compiled packer tool not found at '$SHARD_TOOL_PATH'."
  echo "GSDL: Please report this as a bug to the game_sdl shard maintainer."
  exit 1
fi

# Ensure the target ./bin directory exists
mkdir -p "$TARGET_DIR"

# Copy the binary and make it executable
cp "$SHARD_TOOL_PATH" "$TARGET_TOOL_PATH"
chmod +x "$TARGET_TOOL_PATH"

echo "GSDL: Packer tool successfully installed at '$TARGET_TOOL_PATH'"
echo "GSDL: You can now run it with: ./bin/gsdl-packer --help"
