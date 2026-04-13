#!/bin/bash

# GSDL Linux Release Test Script
# 1. Clean and Build
rm -rf build/release
make release-package-linux EXAMPLE=full

# 2. Check the build artifact directory
echo -e "\n--- Folder Contents ---"
# Find the actual release folder (name includes version)
RELEASE_DIR=$(ls -d build/release/full-linux-v*/ 2>/dev/null)

if [ -z "$RELEASE_DIR" ]; then
  echo "❌ Error: Release directory not found!"
  exit 1
fi

ls -F "$RELEASE_DIR"

# 3. Verify Critical Files
echo -e "\n--- File Verification ---"
FILES=("full" "assets.pack" "libSDL3.so.0" "libSDL3_mixer.so.0" "libSDL3_image.so.0" "libSDL3_ttf.so.0")

for FILE in "${FILES[@]}"; do
  if [ -f "$RELEASE_DIR/$FILE" ]; then
    echo "✅ Success: $FILE found."
  else
    echo "❌ Error: $FILE is missing!"
  fi
done

# 4. Verify the Tar archive
echo -e "\n--- Tar Archive Check ---"
TAR_FILE=$(ls build/release/full-linux-v*.tar.gz 2>/dev/null)
if [ -f "$TAR_FILE" ]; then
  echo "✅ Success: $TAR_FILE created."
  echo "Listing TAR contents:"
  tar -ztf "$TAR_FILE" | grep -E "full$|assets.pack|libSDL3.*so"
else
  echo "❌ Error: Tar file was not created!"
fi

echo -e "\n--- Dependency Check (Local) ---"
if [ -f "$RELEASE_DIR/full" ]; then
  echo "Checking binary dependencies (ldd):"
  ldd "$RELEASE_DIR/full" | grep -i "sdl3"
fi
