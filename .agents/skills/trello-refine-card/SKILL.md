---
name: trello-refine-card
description: Refine Trello card titles and descriptions to be concise yet detailed enough for AI implementation. Use when you need to optimize a Trello card's context before starting development.
---

# Trello Refine Card

This skill enables you to search for a Trello card, analyze its current title and description, and refine them to be professional, concise, and detailed. It specifically aims to make cards "implementation-ready" for AI agents.

## Workflow

### 1. Find the Card
Identify the `boardName` (optional if `boardId` is in config) and `cardSearch` (partial title) from the user's request.
Run the search command:
```bash
# If boardId is in config:
node scripts/trello_refine_card.js search "<cardSearch>"

# To search a specific board by name:
node scripts/trello_refine_card.js search "<boardName>" "<cardSearch>"
```
This will return the card's `id`, current `name`, and `desc`.

### 2. Initial Refinement
Analyze the current name and description returned by the search command. **The existing description MUST be used as the primary source of context.**
- **Context Preservation:** Ensure all original requirements, constraints, and technical details from the current description are carried over.
- **Conciseness:** Remove fluff and redundant information.
- **Professionalism:** Ensure the tone is appropriate for a technical task.
- **Detailed Context:** Expand on technical requirements or goals based on available context (e.g., repository structure, related files).

### 3. Clarifying Questions
If the card's requirements (even after analyzing the existing description) are still vague (e.g., "Fix the bug"), use the `ask_user` tool to gather more details.
Ask specifically about:
- Expected behavior vs. actual behavior.
- Specific files or components involved.
- Any known constraints or dependencies.

### 4. Final Polish
Incorporate the existing context and any user feedback into a final version of the suggested name and description.
The final description should follow a structured format:
- **Goal:** Clear statement of what needs to be achieved.
- **Context:** Why this task is necessary (drawing from the original description).
- **Technical Details:** Specific steps, files, or API endpoints.
- **Definition of Done:** Clear criteria for success.

### 5. Review & Confirmation
**MANDATORY:** You MUST display the refined **Suggested Name** and **Description** as plain text in the chat *before* using any tools. This allows the user to review the content without execution overhead.

Note: The card name itself will NOT be changed. The suggested name will be added to the top of the description in a `### ` header.
You can then use the `preview` command to show a formatted version:
```bash
node scripts/trello_refine_card.js preview "<cardId>" "<suggestedName>" "<newDesc>"
```
**MUST ASK:** "Do you want me to update the Trello card with these changes?"

### 6. Update Trello
ONLY after receiving explicit confirmation from the user, apply the changes to the Trello card:
```bash
node scripts/trello_refine_card.js update "<cardId>" "<suggestedName>" "<newDesc>"
```
**Automatic Movement:** If a `refinedListId` is configured in `.pi/settings.json` (within the `trello` object) or `.gemini/trello_config.json`, the card will also be moved to that list during the update.

## Configuration
The script looks for configuration in the following locations (in order):
1.  `.gemini/trello_config.json`
2.  `.pi/settings.json` (under the `trello` key)
3.  Global skill configuration

Example `.pi/settings.json`:
```json
{
  "trello": {
    "boardId": "your-board-id",
    "refinedListId": "your-refined-list-id"
  }
}
```

## Tips for AI Agents
- **Contextual Baseline:** Always treat the existing description as the "source of truth." Never discard technical details found in the original card unless they are explicitly superseded by user feedback.
- **Be proactive:** Suggest improvements to the description that the user might have missed, while remaining faithful to the original intent.
- **Stay structured:** Use Markdown in the Trello description for better readability.
- **Card Names:** Do not change the original Trello card names. Put your proposed professional title at the top of the description in a `### ` header.
- **Validate:** Ensure the `cardId` is correct before attempting an update.
- **Always Verify:** Never update the Trello ticket without showing the user the final proposed version and getting their approval.
