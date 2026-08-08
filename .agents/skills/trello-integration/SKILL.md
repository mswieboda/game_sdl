---
name: trello-integration
description: Integrates with Trello to manage tasks, fetch card details, and facilitate starting new development cards. Use when the user asks to manage Trello tasks, start a new Trello card, or search for Trello card context.
---

# Trello Integration Skill

This skill provides functionality to interact with Trello, specifically to start new development cards from a 'todo' list and to search for existing card contexts.

## Configuration

Before using this skill, ensure the following environment variables are set and the Trello configuration is properly set up:

-   `TRELLO_API_KEY`: Your Trello API Key.
-   `TRELLO_API_TOKEN`: Your Trello API Token.

The skill will attempt to load Trello board and list IDs (`boardId`, `todoListId`, `inDevListId`) in the following order:

1.  **Project-specific `.gemini/trello_config.json`**:
    Create a `trello_config.json` file inside a `.gemini` directory in your project's root. Example:
    ```json
    {
      "boardId": "YOUR_PROJECT_BOARD_ID",
      "todoListId": "YOUR_PROJECT_TODO_LIST_ID",
      "inDevListId": "YOUR_PROJECT_IN_DEV_LIST_ID"
    }
    ```
2.  **Project-specific `.pi/settings.json`**: (For backward compatibility)
    If a `trello` key exists in your project's `.pi/settings.json`, it will be used.
3.  **Global skill `references/trello_config.json`**:
    This file is located at `/Users/matt/.gemini/skills/trello-integration/references/trello_config.json` (or wherever your skill is installed). You can update this file if you want a default configuration across all projects.

## Usage

### 1. Start a New Trello Card

To start working on a new Trello card from your 'todo' list or by searching:

**Trigger phrases:** "start a trello card", "new trello card", "select a trello task"

**Workflow:**

1.  Run the `scripts/trello_start_card.js` script to fetch the top 5 cards from the 'todo' list.
    ```bash
    node scripts/trello_start_card.js
    ```
    The script will output a JSON object. If `status` is "success" and `message` contains the selection prompt, proceed to step 2. If `status` is "success" but `message` indicates no cards, inform the user. If `status` is "error", report the error message.

2.  If a selection prompt is returned by `trello_start_card.js`, use the `ask_user` tool to present this prompt to the user and get their selection.
    **Example of `ask_user` call (adjust `question` based on actual script output):**
    ```tool_code
    ask_user({
      questions: [{
        question: "--- todo (top 5) ---\\n[1] Card 1 Name\\n...\\n[6] Search for a card\\nChoose a card (1-5 to select, 6 to search, or 0 to cancel):",
        header: "Trello Card Selection",
        type: "text",
        placeholder: "Enter 1-6 or 0 to cancel"
      }]
    })
    ```
    Capture the user's input.

3.  If the user selects a card (1-5), run:
    ```bash
    node scripts/trello_start_card.js <user_selection>
    ```
    If the user selects `6` (Search):
    a. Run `node scripts/trello_start_card.js 6`. It will return `{ "status": "search_required", "message": "Enter search string: " }`.
    b. Use `ask_user` to get the search string from the user.
    c. Run `node scripts/trello_start_card.js 6 "<search_string>"`. It will return a JSON with search results.
    d. Use `ask_user` to let the user select a card from the search results.
    e. Run `node scripts/trello_start_card.js 6 "<search_string>" <search_selection>`.

4.  If the final output status is "success", use the `cardContext` from the JSON output to understand the task and proceed with development. If the status is "cancelled" or "error", inform the user.

### 2. Search for Trello Card Context

To search for the context of an existing Trello card:

**Trigger phrases:** "search trello card", "find trello card context", "what is on trello card X"

**Workflow:**

1.  Identify the `boardName` and `cardSearch` (partial title) from the user's request. If either is unclear, use `ask_user` to clarify with the user.
2.  Run the `scripts/trello_search_card.js` script with the identified parameters.
    ```bash
    node scripts/trello_search_card.js "<boardName>" "<cardSearch>"
    ```
    (Ensure `boardName` and `cardSearch` are quoted if they contain spaces.)
3.  The script will output a JSON object containing `status`, `message`, `and details`.
4.  If the status is "success", provide the `message` (which contains the card context) to the user. If the status is "error", inform the user about the issue.
