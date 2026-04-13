#!/bin/bash

# GSDL Linux Release Test Script

# 0. Restore system libraries for building
echo "Restoring system libraries for build..."
if [ -d ~/sdl3_test_backup ] && [ "$(ls -A ~/sdl3_test_backup)" ]; then
  sudo mv ~/sdl3_test_backup/libSDL3* /usr/local/lib/
  sudo ldconfig
fi

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

ls -lah "$RELEASE_DIR"

# 3. Verify Critical Files
echo -e "\n--- File Verification ---"
FILES=("full" "assets.pack" "libSDL3.so.0" "libSDL3_mixer.so.0" "libSDL3_image.so.0" "libSDL3_ttf.so.0")

for FILE in "${FILES[@]}"; do
  if [ -f "$RELEASE_DIR/$FILE" ]; then
    SIZE=$(ls -lh "$RELEASE_DIR/$FILE" | awk '{print $5}')
    echo "✅ Success: $FILE found (Size: $SIZE)."
  else
    echo "❌ Error: $FILE is missing!"
  fi
done

# 4. Hide system libraries for portability test
echo -e "\n--- Hiding system libraries for portability test ---"
mkdir -p ~/sdl3_test_backup
sudo mv /usr/local/lib/libSDL3* ~/sdl3_test_backup/
sudo ldconfig

# 5. Verify local dependency resolution
echo -e "\n--- Dependency Check (Local) ---"
if [ -f "$RELEASE_DIR/full" ]; then
  echo "Checking binary dependencies (ldd):"
  ldd "$RELEASE_DIR/full" | grep -i "sdl3"
fi

echo -e "\n--- Test Instructions ---"
echo "System libraries are now HIDDEN."
echo "To test the release, run:"
echo "cd $RELEASE_DIR && ./full"
echo ""
echo "To restore your system when done:"
echo "sudo mv ~/sdl3_test_backup/libSDL3* /usr/local/lib/ && sudo ldconfig"
