import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

/**
 * Pi Extension Entry Point
 */
export default function (pi: ExtensionAPI) {
  // Subscribe to session start
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Extension Loaded", "info");
  });

  // Register a custom tool
  pi.registerTool({
    name: "my_tool",
    label: "My Tool",
    description: "What this tool does (shown to LLM)",
    parameters: Type.Object({
      text: Type.String({ description: "Sample parameter" }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return {
        content: [{ type: "text", text: `You said: ${params.text}` }],
        details: { data: params.text },
      };
    },
  });

  // Register a slash command
  pi.registerCommand("my-cmd", {
    description: "A custom slash command",
    handler: async (args, ctx) => {
      ctx.ui.notify(`Command args: ${args}`, "info");
    },
  });
}
```
