# Project: GameSDL (GSDL)
- **Language:** Crystal 1.19.1
- **Dependency:** SDL3 bindings (`../sdl3`).

## Workflow & Constraints
- **Reading Bindings:** Copy `../sdl3` source or specific C headers to `./tmp` to inspect.
    - SDL3 headers in `/opt/homebrew/Cellar/sdl3/3.4.4/include/SDL3`
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
- **Visual Verification:** For GUI/UI examples, perform automated visual checks on macOS. Run the example with a short `timeout` in the background, sleep for 2.0 seconds to allow the window to render, resolve the game process PID to its macOS Window ID, take a window-specific screen capture (playing the sound so the user hears it, and excluding drop shadows) to your conversation's brain/artifacts directory, and call `wait` to cleanly exit:
  - Command:
    ```bash
    timeout 4 ./build/foo &
    sleep 2.0
    GAME_PID=$(pgrep -f "./build/foo" | grep -v "timeout" | head -n 1)
    WINDOW_ID=$(get_window_id "$GAME_PID" | tail -n 1)
    screencapture -o -l "$WINDOW_ID" /Users/matt/.gemini/antigravity-cli/brain/<conversation-id>/test_ui_screenshot.png
    wait
    ```
- **Regression Checks:** If your task affects a specific subsystem (e.g., `GSDL::Audio`), identify and run the relevant example (e.g., `examples/audio.cr`).
- **Error Resolution:** The `Makefile` includes `--error-trace`. Focus on the first few lines of a compile error to identify the root cause.
- **Validation Mandate:** Frequent compilation checks are mandatory. A task is not complete until behavioral correctness is verified through a successful build and run.
- **Version Bump Suggestion:** After completing a significant task or feature, you must recommend the appropriate semantic version bump. Check `shard.yml` or `git tags` to determine the current version first.
  - **Minor (`0.Y.0`):** Recommended if there are any **breaking changes** (deleted classes, changed method signatures, or major architectural shifts).
  - **Patch (`0.x.Y`):** Recommended if the changes are **purely additive** (new features, new classes) or backward-compatible bug fixes.
  - **Remind User:** Remind the user they can use `./bump (major|minor|patch)` to perform the bump manually. Do not execute the script yourself.

## Do Not Do
- **Library Files:** NEVER edit files in `./lib/`. Summarize proposed changes for the user to apply to the source repositories (e.g., `sdl3`).
- **Git Operations:** NO write commands (`git add`, `git commit`, `git stage`). Use read-only commands only.

<!-- br-agent-instructions-v1 -->

---

## Beads Workflow Integration

This project uses [beads_rust](https://github.com/Dicklesworthstone/beads_rust) (`br`/`bd`) for issue tracking. Issues are stored in `.beads/` and tracked in git.

### Essential Commands

NOTE: always append `--json` param to each command, so it is machine readable tailored for AI usage.

```bash
# View ready issues (open, unblocked, not deferred)
br ready --json              # or: bd ready

# List and search
br list --status=open --json # All open issues
br show <id> --json          # Full issue details with dependencies
br search "keyword" --json   # Full-text search

# Create and update
br create --title="..." --description="..." --type=task --priority=2 --json
br create --title="..." --description="..." --type=epic --priority=2 --json
br update <id> --status=in_progress --json
br update <id> --notes "..." --json
br close <id> --reason="Completed" --json
br close <id1> <id2> --json  # Close multiple issues at once

# Sync with git
br sync --flush-only --json  # Export DB to JSONL
br sync --status --json      # Check sync status
```

### Workflow Pattern

Determine if the request is a **Beads-tracked task** (e.g., a major feature, or selected from triage) or an **untracked task** (minor bug fix, quick visual tweak, or direct user prompt that does not need formal tracking).

#### A. For Beads-Tracked Tasks:
1. **Start**: Run `bv --robot-triage` to find actionable work if starting a major feature.
2. **Claim**: Use `br update <id> --status=in_progress --json`
3. **Work**: Implement the task
4. **Complete**: Use `br close <id> --json`
5. **Sync**: Always run `br sync --flush-only --json` at session end

#### B. For Untracked Tasks (Minor Fixes / Quick Prompts):
1. **Work**: Implement the task directly. Do NOT run any `br` or `bv` commands.
2. **Complete**: Verify compilation and behavioral correctness.

### Key Concepts

- **Dependencies**: Issues can block other issues. `bv --robot-triage` shows only open, unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog (use numbers 0-4, not words)
- **Types**: task, bug, feature, epic, chore, docs, question
- **Blocking**: `br dep add <issue> <depends-on>` to add dependencies

### Best Practices

- Check `bv --robot-triage` when asked to find available work or major features to implement.
- Update status as you work (in_progress → closed) only for tracked tasks.
- **Do NOT create a Beads task for every prompt.** For minor bug fixes, quick adjustments, or direct user requests that do not require tracking, skip creating/using Beads tasks. Only create tasks for major features/refactors or when explicitly asked by the user.
- Create new issues with `br create --json` when you discover separate, significant tasks/bugs that need proper tracking.
- Always sync before ending session if any Beads operations were performed.

### Session Termination Procedures

**CRITICAL REQUIREMENT:** Always ask the user to verify the UI or feature behavioral correctness first. Do NOT run any `br update <id> --notes ...` or `br close` commands until the user has explicitly confirmed they have verified the implementation and it works perfectly.

Only after they confirm and say "wrap this up", "wrap up task", "task completed", or "sync tasks", execute the following sequence based on task type:

#### If the task was tracked via Beads:
1. **Summarize Work:** Use `br update <id> --notes "..." --json` to record a technical summary of what was accomplished, any technical debt introduced, and specific findings for the GSDL biotech logic.
2. **Handle Discoveries:** If new bugs or dependencies were found, create them now using `br create "..." --type bug/chore --deps discovered-from:<ID> --json`.
3. **Sync to Disk:** Run `br sync --flush-only --json`.
4. **Final Closure:** If the task is truly finished, run `br close <ID> --json`.
5. **Summarize to User:** Summarize changes, and task updates to user, and suggest a commit message. DO NOT use any `git` write commands, the user will perform them manually.

#### If the task was UNTRACKED (minor fixes / quick prompts):
1. **Summarize to User:** Summarize changes directly and suggest a commit message. DO NOT use any `git` write commands, and DO NOT run any `br` or `bv` commands.

<!-- end-br-agent-instructions -->

<!-- bv-agent-instructions-v2 -->

---

## Beads Workflow Integration

This project uses [beads_rust](https://github.com/Dicklesworthstone/beads_rust) (`br`) for issue tracking and [beads_viewer](https://github.com/Dicklesworthstone/beads_viewer) (`bv`) for graph-aware triage. Issues are stored in `.beads/` and tracked in git.

### Using bv as an AI sidecar

bv is a graph-aware triage engine for Beads projects (.beads/beads.jsonl). Instead of parsing JSONL or hallucinating graph traversal, use robot flags for deterministic, dependency-aware outputs with precomputed metrics (PageRank, betweenness, critical path, cycles, HITS, eigenvector, k-core).

**Scope boundary:** bv handles *what to work on* (triage, priority, planning). `br` handles creating, modifying, and closing beads.

**CRITICAL: Use ONLY --robot-* flags. Bare bv launches an interactive TUI that blocks your session.**

#### The Triage Workflow:

When asked to start a new task **`bv --robot-triage` is your single entry point.** It returns everything you need in one call:
- `quick_ref`: at-a-glance counts + top 3 picks
- `recommendations`: ranked actionable items with scores, reasons, unblock info
- `quick_wins`: low-effort high-impact items
- `blockers_to_clear`: items that unblock the most downstream work
- `project_health`: status/type/priority distributions, graph metrics
- `commands`: copy-paste shell commands for next steps

```bash
bv --robot-triage        # THE MEGA-COMMAND
bv --robot-next          # Minimal: just the single top pick + claim command

# Token-optimized output (TOON) for lower LLM context usage:
bv --robot-triage --format toon
```

#### Other bv Commands

| Command | Returns |
|---------|---------|
| `--robot-plan` | Parallel execution tracks with unblocks lists |
| `--robot-priority` | Priority misalignment detection with confidence |
| `--robot-insights` | Full metrics: PageRank, betweenness, HITS, eigenvector, critical path, cycles, k-core |
| `--robot-alerts` | Stale issues, blocking cascades, priority mismatches |
| `--robot-suggest` | Hygiene: duplicates, missing deps, label suggestions, cycle breaks |
| `--robot-diff --diff-since <ref>` | Changes since ref: new/closed/modified issues |
| `--robot-graph [--graph-format=json\|dot\|mermaid]` | Dependency graph export |

#### Scoping & Filtering

```bash
bv --robot-plan --label backend              # Scope to label's subgraph
bv --robot-insights --as-of HEAD~30          # Historical point-in-time
bv --recipe actionable --robot-plan          # Pre-filter: ready to work (no blockers)
bv --recipe high-impact --robot-triage       # Pre-filter: top PageRank scores
```
<!-- end-bv-agent-instructions -->
