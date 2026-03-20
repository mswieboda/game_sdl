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

## Compiling, and Testing
- **Full Verification:** Usually compile `examples/full.cr` to verify library-wide integrity and catch regressions. Or build the specific example we're working on first `examples/foo.cr`.
  - Command: `make build EXAMPLE=full`
- **Functional Testing:** Run a specific example to exercise changes. Capture logs and exit automatically:
  - Command: `timeout 5s make run EXAMPLE=foo || true`
- **Regression Checks:** If your task affects a specific subsystem (e.g., `GSDL::Audio`), identify and run the relevant example (e.g., `examples/audio.cr`).
- **Error Resolution:** The `Makefile` includes `--error-trace`. Focus on the first few lines of a compile error to identify the root cause.
- **Validation Mandate:** Frequent compilation checks are mandatory. A task is not complete until behavioral correctness is verified through a successful build and run.
- **Version Bump Suggestion:** After completing a significant task or Trello card, you must recommend the appropriate semantic version bump. Check `shard.yml` or `git tags` to determine the current version first.
  - **Minor (`0.Y.0`):** Recommended if there are any **breaking changes** (deleted classes, changed method signatures, or major architectural shifts).
  - **Patch (`0.x.Y`):** Recommended if the changes are **purely additive** (new features, new classes) or backward-compatible bug fixes.
  - **Remind User:** Remind the user they can use `./bump (major|minor|patch)` to perform the bump manually. Do not execute the script yourself.

## Do Not Do
- **Library Files:** NEVER edit files in `./lib/`. Summarize proposed changes for the user to apply to the source repositories (e.g., `sdl3`).
- **Git Operations:** NO write commands (`git add`, `git commit`, `git stage`). Use read-only commands only.
- **Trello:** DO NOT modify the Trello board or cards.
