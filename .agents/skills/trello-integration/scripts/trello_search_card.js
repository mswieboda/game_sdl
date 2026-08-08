// trello_search_card.js
const fs = require('fs');
const path = require('path');

async function trelloSearchCard() {
  const TRELLO_API_KEY = process.env.TRELLO_API_KEY;
  const TRELLO_API_TOKEN = process.env.TRELLO_API_TOKEN;

  if (!TRELLO_API_KEY || !TRELLO_API_TOKEN) {
    console.error("Error: TRELLO_API_KEY and TRELLO_API_TOKEN env vars must be set.");
    process.exit(1);
  }

  function findConfig(relativePath) {
    let currentDir = process.cwd();
    while (true) {
      const fullPath = path.join(currentDir, relativePath);
      if (fs.existsSync(fullPath)) return fullPath;
      const parentDir = path.dirname(currentDir);
      if (parentDir === currentDir) break;
      currentDir = parentDir;
    }
    return null;
  }

  let trelloSettings;
  const projectGeminiConfigPath = findConfig('.gemini/trello_config.json');
  const projectPiConfigPath = findConfig('.pi/settings.json'); // For backward compatibility
  const globalSkillConfigPath = path.join(__dirname, '../references/trello_config.json');

  if (projectGeminiConfigPath) {
    try {
      trelloSettings = JSON.parse(fs.readFileSync(projectGeminiConfigPath, 'utf-8'));
      console.error(`Using project-specific configuration at ${projectGeminiConfigPath}`);
    } catch (e) {
      console.error(`Error reading or parsing project .gemini/trello_config.json: ${e.message}`);
      process.exit(1);
    }
  } else if (projectPiConfigPath) {
    try {
      const piSettings = JSON.parse(fs.readFileSync(projectPiConfigPath, 'utf-8'));
      trelloSettings = piSettings.trello; // Extract 'trello' key from .pi/settings.json
      console.error(`Using project-specific configuration at ${projectPiConfigPath}`);
    } catch (e) {
      console.error(`Error reading or parsing project .pi/settings.json: ${e.message}`);
      process.exit(1);
    }
  } else if (fs.existsSync(globalSkillConfigPath)) {
    try {
      trelloSettings = JSON.parse(fs.readFileSync(globalSkillConfigPath, 'utf-8'));
      console.error("Using global skill's trello_config.json");
    } catch (e) {
      console.error(`Error reading or parsing global skill trello_config.json: ${e.message}`);
      process.exit(1);
    }
  }


  if (!trelloSettings || !trelloSettings.boardId || !trelloSettings.todoListId || !trelloSettings.inDevListId) {
    console.error("Error: Trello boardId, todoListId, and inDevListId must be configured. Checked project-level .gemini/trello_config.json, project-level .pi/settings.json, and global skill trello_config.json.");
    process.exit(1);
  }

  const boardName = process.argv[2];
  const cardSearch = process.argv[3];

  if (!boardName || !cardSearch) {
    console.error("Error: boardName and cardSearch are required parameters.");
    process.exit(1);
  }

  try {
    const boardsUrl = `https://api.trello.com/1/members/me/boards?key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}`;
    const boardsRes = await fetch(boardsUrl);

    if (!boardsRes.ok) {
      console.error(`Trello API error fetching boards: ${boardsRes.status} ${boardsRes.statusText}`);
      process.exit(1);
    }

    const boards = await boardsRes.json();
    const matchedBoard = boards.find((b) => b.name.toLowerCase().includes(boardName.toLowerCase()));

    if (!matchedBoard) {
      console.log(JSON.stringify({ status: "error", message: `No board found matching "${boardName}"` }));
      return;
    }

    const url = `https://api.trello.com/1/boards/${matchedBoard.id}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}`;
    const res = await fetch(url);

    if (!res.ok) {
      console.error(`Trello API error: ${res.status} ${res.statusText}`);
      process.exit(1);
    }

    const cards = await res.json();
    const matched = cards.find((c) => c.name.toLowerCase().includes(cardSearch.toLowerCase()));

    if (!matched) {
      console.log(JSON.stringify({ status: "error", message: `No card found matching "${cardSearch}" in board "${matchedBoard.name}"` }));
      return;
    }

    const msg = `Here is the context for Trello card "${matched.name}":\n\n${matched.desc || "No description provided."}`;

    console.log(JSON.stringify({
      status: "success",
      message: msg,
      details: { board: matchedBoard.name, card: matched.name }
    }));

  } catch (err) {
    console.error(`Error fetching Trello data: ${err.message || err}`);
    process.exit(1);
  }
}

trelloSearchCard();
