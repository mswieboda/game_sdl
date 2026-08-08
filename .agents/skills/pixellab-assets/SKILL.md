---
name: pixellab-assets
description: Generate pixel art game assets (characters, animations, top-down tilesets, map objects, isometric tiles) using PixelLab. Use when the user needs to create visual assets for the Jolly Roger project or any pixel-art game.
---

# PixelLab Assets

## Overview

This skill leverages the PixelLab MCP server to generate high-quality pixel art assets. It handles character creation with multiple viewpoints, complex animations, seamless terrain tilesets, and style-matched map objects.

## Core Capabilities

### 1. Characters & Animations
Create characters with 4 or 8 directional views and queue animations immediately.

- **Workflow:**
  1. `create_character(description="cute wizard", n_directions=8, body_type="humanoid")`
  2. Use the returned `character_id` to queue animations immediately.
  3. Check status with `get_character(character_id="...")`.

- **References:**
  - See [humanoid_animations.md](references/humanoid_animations.md) for a full list of humanoid animation IDs.
  - See [quadruped_templates.md](references/quadruped_templates.md) for animal templates and animations.

### 2. Top-Down Tilesets & Chaining
Generate seamless Wang tilesets for terrain transitions. Chaining allows for complex world-building (e.g., Ocean → Beach → Grass).

- **Workflow:**
  1. `create_topdown_tileset(lower_description="ocean", upper_description="beach")`
  2. Retrieve the `upper_base_tile_id` (beach ID) from the result once completed.
  3. Create the next tileset: `create_topdown_tileset(lower_description="beach", upper_description="grass", lower_base_tile_id=beach_id)`.

- **Tips:**
  - Use `high top-down` for RTS-style maps.
  - Use `low top-down` for RPG-style maps.

### 3. Map Objects & Style Matching
Create standalone objects (trees, chests, buildings) with transparent backgrounds. Use "Style Matching Mode" to blend with existing tiles.

- **Style Matching Workflow:**
  1. Provide a `background_image` (e.g., a portion of your map).
  2. PixelLab AI will analyze the style and generate an object that matches the colors, shading, and detail.
  3. Use `create_map_object(description="stone fountain", background_image='{"type": "path", "path": "assets/gfx/map_preview.png"}')`.

### 4. Isometric & Pro Tiles
For games with isometric perspective or when advanced style transfer is needed.

- **Isometric Tiles:** Use `create_isometric_tile(description="grass tile", tile_shape="block")`.
- **Pro Tiles:** Use `create_tiles_pro` for multiple variations or to copy styles from existing images using `style_images`.

## Best Practices

- **Non-Blocking:** Jobs take 2-5 minutes. You do not need to wait for one job to finish before queuing others (e.g., queue all animations at once).
- **Consistency:** Align `outline`, `shading`, `detail`, and `view` across all asset types for a coherent visual style.
- **Seed Synchronization:** Use the same `seed` for related tiles to maintain texture and palette consistency.
- **Cleanup:** Delete unneeded example files from the skill directory if they were not removed during initialization.
