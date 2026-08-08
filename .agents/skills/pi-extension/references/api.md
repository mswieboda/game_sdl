# Extension API Reference

## ExtensionAPI (pi)
The entry point for extensions.

### Core Methods
- `pi.on(eventName, handler)`: Subscribe to lifecycle and session events.
- `pi.registerTool(definition)`: Register a tool the LLM can call.
- `pi.registerCommand(name, options)`: Register a slash command (e.g., `/mycommand`).
- `pi.registerShortcut(shortcut, options)`: Register a keyboard shortcut (e.g., `ctrl+shift+p`).
- `pi.registerFlag(name, options)`: Register a CLI flag.
- `pi.sendMessage(message)`: Inject a message into the session.
- `pi.registerMessageRenderer(type, renderer)`: Custom TUI renderer for messages.
- `pi.exec(command, args, options)`: Execute shell commands.
- `pi.registerProvider(name, config)`: Dynamically register/override model providers.

### Tool Management
- `pi.getActiveTools()`: Get names of currently enabled tools.
- `pi.getAllTools()`: Get all registered tools.
- `pi.setActiveTools(names)`: Enable a specific set of tools.

### LLM Controls
- `pi.setModel(model)`: Switch the current model.
- `pi.setThinkingLevel(level)`: Set reasoning level ("off", "minimal", "low", "medium", "high", "xhigh").
- `pi.compact()`: Trigger session compaction manually.

---

## ExtensionContext (ctx)
Passed to event handlers and tool `execute` methods.

### UI (ctx.ui)
- `ctx.ui.notify(message, type)`: Show a non-blocking notification ("info", "warning", "error").
- `ctx.ui.confirm(title, body, options)`: Show a Yes/No dialog.
- `ctx.ui.select(title, options)`: Show a selection menu.
- `ctx.ui.input(title, placeholder)`: Request single-line text.
- `ctx.ui.editor(title, prefilled)`: Open a multi-line editor.
- `ctx.ui.custom(factory, options)`: Use a custom TUI component.
- `ctx.ui.setStatus(id, text)`: Set a status message in the footer.
- `ctx.ui.setWidget(id, content, options)`: Display a widget above/below the editor.
- `ctx.ui.setWorkingMessage(message)`: Set the message shown during LLM thinking.

### Session & Agent
- `ctx.sessionManager`: Access the current session, history, and branches.
- `ctx.modelRegistry`: List and find available models.
- `ctx.agent`: Access agent-level state and system prompt.
- `ctx.hasUI`: Boolean check if running in interactive/TUI mode.

---

## Tool Definition
Used with `pi.registerTool({ ... })`.

```typescript
{
  name: string;        // Unique identifier (e.g., "my_tool")
  label: string;       // Display name in UI
  description: string; // Instructions for the LLM
  parameters: TObject; // TypeBox schema for inputs
  execute: (toolCallId, params, signal, onUpdate, ctx) => Promise<ToolResult>;
  renderCall?: (args, theme) => Component;
  renderResult?: (result, options, theme) => Component;
}
```

**ToolResult Shape:**
```typescript
{
  content: [{ type: "text", text: string }]; // Sent to LLM
  details?: Record<string, any>;             // For rendering & state
  isError?: boolean;                         // Indicate failure to LLM
}
```
