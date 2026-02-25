# Project: GameSDL (GSDL)
- **Language:** Crystal 1.19.1
- **Dependency:** SDL3 bindings (`../sdl3`).

## Workflow & Constraints
- **Reading Bindings:** Copy `../sdl3` source or specific C headers to `./tmp` to inspect.
    - SDL3 headers in `/opt/homebrew/Cellar/sdl3/3.4.0/include/SDL3`
    - SDL3_image headers in `/opt/homebrew/Cellar/sdl3_image/3.4.0/include/`
    - SDL3_ttf headers in `/opt/homebrew/Cellar/sdl3_ttf/3.2.2/include/`
- **Editing Bindings:** **Read-only access** to `../sdl3`. Write suggested changes to `./tmp/sdl3.cr-changes`. Summarize changes to the user so they can update `../sdl3`.
- **Run Examples:** `make run EXAMPLE=full` (runs `examples/full.cr`).
    - `full.cr` tests compiling mostly the whole libary.
    - Specific examples (e.g., `examples/sprite.cr`) test isolated components like `GSDL::Sprite`.

## Coding / Convention Standards
- Prefer `SDL3::` wrappers over `LibSDL3::`.
- New drawables need a z_index and a DrawCommand struct.
- Imports or require statements are centralized in `src/game_sdl.cr`. Do not add per-file `require` unless stricly necessary (compile error).
- Do not run `crystal format`
- Trim all whitespace for any changes or new files
