---
name: pi-extension
description: Create, modify, and test TypeScript extensions for the `pi` coding agent. Use when asked to extend `pi` with custom tools, commands, event interception, or TUI components.
---

# Pi Extension

Extensions are TypeScript modules that extend the `pi` coding agent's behavior. They can subscribe to lifecycle events, register custom tools, add slash commands, and customize the TUI.

## Quick Start

Create a new extension by copying `assets/boilerplate.ts` to `~/.pi/agent/extensions/my-extension.ts`.

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Extension loaded!", "info");
  });
}
```

## Extension Locations

Extensions are auto-discovered from:
- `~/.pi/agent/extensions/*.ts` (Global)
- `.pi/extensions/*.ts` (Project-local)

## Core Capabilities

### 1. Custom Tools
Register tools the LLM can call via `pi.registerTool()`. Tools appear in the system prompt.
- Use `TypeBox` for parameter schemas.
- Return `content` (for LLM) and `details` (for rendering/state).
- Implement `renderCall` and `renderResult` for custom TUI display.

### 2. Custom Commands
Register slash commands like `/mycommand` via `pi.registerCommand()`.

### 3. Event Interception
Block or modify tool calls, user input, or system prompts by returning `{ block: true }` or `{ transform: { ... } }` from event handlers.
- See [references/events.md](references/events.md) for available events.

### 4. User Interaction (TUI)
Prompt users via `ctx.ui` (select, confirm, input, notify, custom).
- See [references/api.md](references/api.md) for the full UI API.

## Workflow: Create and Test

1. **Scaffold:** Copy `assets/boilerplate.ts` to a new `.ts` file in an extension directory.
2. **Implement:** Add event listeners, tools, or commands.
3. **Test:** Run `pi -e ./path/to/extension.ts` for quick testing.
4. **Deploy:** Move the file to `~/.pi/agent/extensions/` for auto-discovery.
5. **Reload:** Use the `/reload` command in an active `pi` session to pick up changes.

## References
- [references/api.md](references/api.md) - Full API reference for `ExtensionAPI` and `ctx.ui`.
- [references/events.md](references/events.md) - List of all events and their object shapes.
