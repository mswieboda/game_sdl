// trello_refine_card.js
const fs = require('fs');
const path = require('path');

async function main() {
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

  let trelloSettings = {};
  const projectGeminiConfigPath = findConfig('.gemini/trello_config.json');
  const projectPiConfigPath = findConfig('.pi/settings.json');
  const globalSkillConfigPath = path.join(__dirname, '../../trello-integration/references/trello_config.json');

  if (projectGeminiConfigPath) {
    try {
      trelloSettings = JSON.parse(fs.readFileSync(projectGeminiConfigPath, 'utf-8'));
      console.error(`Using project-specific configuration at ${projectGeminiConfigPath}`);
    } catch (e) {
      console.error(`Error reading ${projectGeminiConfigPath}: ${e.message}`);
    }
  } else if (projectPiConfigPath) {
    try {
      const piSettings = JSON.parse(fs.readFileSync(projectPiConfigPath, 'utf-8'));
      trelloSettings = piSettings.trello || {};
      console.error(`Using project-specific configuration at ${projectPiConfigPath}`);
    } catch (e) {
      console.error(`Error reading ${projectPiConfigPath}: ${e.message}`);
    }
  } else if (fs.existsSync(globalSkillConfigPath)) {
    try {
      trelloSettings = JSON.parse(fs.readFileSync(globalSkillConfigPath, 'utf-8'));
      console.error(`Using global skill configuration at ${globalSkillConfigPath}`);
    } catch (e) {
      console.error(`Error reading ${globalSkillConfigPath}: ${e.message}`);
    }
  }

  const command = process.argv[2];

  if (command === 'search') {
    let boardId = trelloSettings.boardId;
    let cardSearch = process.argv[3];
    let boardName = null;

    // If two arguments are provided, the first is boardName and the second is cardSearch
    if (process.argv.length > 4) {
      boardName = process.argv[3];
      cardSearch = process.argv[4];
      boardId = null; // Explicit board search requested
    }

    if (!cardSearch) {
      console.error("Usage: node trello_refine_card.js search [boardName] <cardSearch>");
      process.exit(1);
    }

    try {
      let targetBoardId = boardId;
      let targetBoardName = "Configured Board";

      if (boardName) {
        const boardsUrl = `https://api.trello.com/1/members/me/boards?key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}`;
        const boardsRes = await fetch(boardsUrl);
        const boards = await boardsRes.json();
        const matchedBoard = boards.find((b) => b.name.toLowerCase().includes(boardName.toLowerCase()));

        if (!matchedBoard) {
          console.log(JSON.stringify({ status: "error", message: `No board found matching "${boardName}"` }));
          return;
        }
        targetBoardId = matchedBoard.id;
        targetBoardName = matchedBoard.name;
      }

      if (!targetBoardId) {
        console.error("Error: No boardId found in config and no boardName provided as argument.");
        process.exit(1);
      }

      const url = `https://api.trello.com/1/boards/${targetBoardId}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}`;
      const res = await fetch(url);
      if (!res.ok) {
        console.error(`Trello API error fetching cards: ${res.status} ${res.statusText}`);
        process.exit(1);
      }
      const cards = await res.json();
      const matched = cards.find((c) => c.name.toLowerCase().includes(cardSearch.toLowerCase()));

      if (!matched) {
        console.log(JSON.stringify({ status: "error", message: `No card found matching "${cardSearch}" in board "${targetBoardName}"` }));
        return;
      }

      console.log(JSON.stringify({
        status: "success",
        card: {
          id: matched.id,
          name: matched.name,
          desc: matched.desc,
          boardName: targetBoardName
        }
      }));
    } catch (err) {
      console.error(`Error: ${err.message}`);
      process.exit(1);
    }
  } else if (command === 'preview' || command === 'update') {
    const cardId = process.argv[3];
    const newName = process.argv[4];
    let newDesc = process.argv[5];

    if (!cardId || !newName || !newDesc) {
      console.error(`Usage: node trello_refine_card.js ${command} <cardId> <newName> <newDesc_or_@file>`);
      process.exit(1);
    }

    // Handle reading description from file to avoid shell escaping issues
    if (newDesc.startsWith('@')) {
      const filePath = newDesc.substring(1);
      try {
        newDesc = fs.readFileSync(filePath, 'utf-8');
      } catch (err) {
        console.error(`Error reading description from file ${filePath}: ${err.message}`);
        process.exit(1);
      }
    }

    const finalDesc = `### \n${newName}\n\n${newDesc}`;

    if (command === 'preview') {
      console.log(JSON.stringify({
        status: "preview",
        cardId: cardId,
        suggestedName: newName,
        newDesc: finalDesc
      }, null, 2));
      return;
    }

    try {
      const url = `https://api.trello.com/1/cards/${cardId}?key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}`;
      const updatePayload = { desc: finalDesc };

      if (trelloSettings.refinedListId) {
        updatePayload.idList = trelloSettings.refinedListId;
      }

      const res = await fetch(url, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json; charset=utf-8' },
        body: JSON.stringify(updatePayload)
      });

      if (!res.ok) {
        console.error(`Trello API error: ${res.status} ${res.statusText}`);
        process.exit(1);
      }

      let successMsg = "Card updated successfully.";
      if (trelloSettings.refinedListId) {
        successMsg += " Card moved to refined list.";
      }
      console.log(JSON.stringify({ status: "success", message: successMsg }));
    } catch (err) {
      console.error(`Error updating card: ${err.message}`);
      process.exit(1);
    }
  } else {
    console.error("Unknown command. Use 'search', 'preview', or 'update'.");
    process.exit(1);
  }
}

main();
