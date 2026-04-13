#!/bin/bash

# 1. Clean and Build
rm -rf build/release
make release-package-win EXAMPLE=full

# 2. Check the build artifact directory
echo -e "\n--- Folder Contents ---"
# Find the actual release folder (name includes version)
RELEASE_DIR=$(ls -d build/release/full-win-v*/ 2>/dev/null)

if [ -z "$RELEASE_DIR" ]; then
  echo "❌ Error: Release directory not found!"
  exit 1
fi

ls -F "$RELEASE_DIR"

# 3. Verify Critical Files
echo -e "\n--- File Verification ---"
FILES=("full.exe" "assets.pack" "SDL3.dll" "SDL3_mixer.dll" "SDL3_image.dll" "SDL3_ttf.dll")

for FILE in "${FILES[@]}"; do
  if [ -f "$RELEASE_DIR/$FILE" ]; then
    echo "✅ Success: $FILE found."
  else
    echo "❌ Error: $FILE is missing!"
  fi
done

# 4. Verify the Zip archive
echo -e "\n--- Zip Archive Check ---"
ZIP_FILE=$(ls build/release/full-win-v*.zip 2>/dev/null)
if [ -f "$ZIP_FILE" ]; then
  echo "✅ Success: $ZIP_FILE created."
  if command -v unzip >/dev/null 2>&1; then
    echo "Listing ZIP contents (checking for nesting and DLLs):"
    unzip -l "$ZIP_FILE" | grep -E "full.exe|SDL3.dll"
  else
    echo "Note: 'unzip' command not found, skipping internal ZIP check."
  fi
else
  echo "❌ Error: Zip file was not created!"
fi
