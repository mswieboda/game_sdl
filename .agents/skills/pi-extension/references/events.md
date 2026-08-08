# Pi Extension Events Reference

Extensions can subscribe to events using `pi.on(eventName, handler)`.

## Session Lifecycle
- `session_start`: When a session is loaded or started.
- `session_shutdown`: Before the session exits.
- `session_before_fork`: Before a session branch is created.
- `session_fork`: After a session branch is created.
- `session_before_switch`: Before switching to a different session.
- `session_switch`: After switching to a different session.
- `session_before_compact`: Before session compaction (can modify summary).
- `session_compact`: After session compaction.

## Agent & Prompt Lifecycle
- `input`: When the user sends a prompt (can intercept or transform).
- `before_agent_start`: Before the LLM turn starts (can inject system/user messages).
- `agent_start`: When the LLM starts its turn.
- `agent_end`: When the LLM finishes its turn.
- `turn_start`: When a specific LLM turn starts (re-starts for each tool call).
- `turn_end`: When a specific LLM turn ends.

## Tool Lifecycle
- `tool_call`: When the LLM initiates a tool call (can block/modify).
- `tool_result`: When a tool execution returns a result.
- `user_bash`: When the user manually runs a command in the TUI terminal.

## Model Lifecycle
- `model_select`: When the current model is changed.
- `thinking_select`: When the thinking level is changed.

---

## Event Object Shapes

### tool_call
```typescript
{
  toolName: string;      // The tool being called
  input: any;            // The LLM-provided parameters
  toolCallId: string;    // Unique ID for the call
}
```
**Return Type (Optional):**
- `{ block: true, reason: string }`: Stop the tool from executing.
- `{ transform: { toolName: string, input: any } }`: Modify the call.

### input
```typescript
{
  text: string;          // The user's input text
}
```
**Return Type (Optional):**
- `{ block: true }`: Stop the input from reaching the LLM.
- `{ transform: { text: string } }`: Modify the input before it's processed.

### before_agent_start
```typescript
{
  messages: Array<Message>; // Current session messages
  systemPrompt: string;     // The system prompt being sent
}
```
**Return Type (Optional):**
- `{ messages: Array<Message> }`: Inject or remove messages.
- `{ systemPrompt: string }`: Modify the system prompt for this turn.

---

## Example: Permission Gate
```typescript
pi.on("tool_call", async (event, ctx) => {
  if (event.toolName === "bash" && event.input.command?.includes("rm -rf")) {
    const ok = await ctx.ui.confirm("Dangerous!", "Allow rm -rf?");
    if (!ok) return { block: true, reason: "Blocked by user" };
  }
});
```
