---
name: game-dev-gsdl
description: Expert guidance for developing 2D games using the GameSDL (GSDL) framework. Use when building game mechanics, rendering primitives, handling input, or managing scenes with GSDL.
---

# Skill: game-dev-gsdl

Expert guidance for developing 2D games using the `GameSDL` (GSDL) framework.

## Project Structure
- **Namespace:** Core classes are under the `GSDL` module.
- **Game:** Main engine. Access via `GSDL::Game.width`, `GSDL::Game.height`, `GSDL::Game.draw`.
- **Scenes:** State containers. Manage via `GSDL::Game.push`, `pop`, `switch`.
- **Entities:** Objects within a scene. Use `add_child` for automatic updates and drawing.

## Graphics & Rendering
### Primitives (GSDL::Draw)
- **Rect:** `rect_fill(x, y, w, h, color, z_index)` or `rect_outline(...)`. Accepts `GSDL::FRect` or `GSDL::Box`.
- **Circle:** `circle_fill(x, y, radius, color, z_index)` or `circle_outline(...)`. Accepts `GSDL::Circle`.
- **Lines/Points:** `line(x1, y1, x2, y2, color, z_index)` and `point(x, y, color, z_index)`.
- **Geometry:** `geometry(vertices, indices, z_index, texture)` for vertex-based rendering.

### Sprite Classes
- **Sprite:** Static image rendering from textures.
- **AnimatedSprite:** Frame-based animations. Requires `AnimationPlayer`.
- **SpriteBase:** Abstract base for custom sprite implementations.

### Specialized Geometry
- **Box / FRect:** Rectangle shapes with position and size.
- **Circle:** Circular shapes with center `x, y` and `radius`.
- **Oval, Pie, Triangle:** Specialized geometry for custom rendering.

## UI Elements
- **Text / TextRotated / RichText:** Flexible text rendering options.
- **HUD:** Layer for overlays (Health, Score, etc.).
- **Message / DialogBox:** Systems for notifications or conversations.
- **ProgressBar / Slider:** Visual controls for ranges and values.
- **Button / Menu:** Interactive selection components.
- **TextInput / TextBox:** Keyboard input elements.

## Common Patterns
- **Game Loop:** `update(dt : Float32)` for logic/input; `draw(draw : GSDL::Draw)` for rendering.
- **Coordinate System:** Origin `(0,0)` is top-left.
- **Input:** Poll `GSDL::Keys` for keyboard state (e.g., `just_pressed?`, `pressed?`).
- **Assets:** Use `TextureManager`, `FontManager`, and `AudioManager`.

## Technical Standards
- **Reference Types:** Use classes for entities to ensure state updates persist across references.
- **Types:** Use `Num` (`Int32 | Float32`) for coordinates and movement calculations.
