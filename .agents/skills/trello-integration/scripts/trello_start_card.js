// trello_start_card.js
const fs = require('fs');
const path = require('path');

async function trelloStartCard() {
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

  try {
    const selectionArg = process.argv[2]; // Expecting selection as the first argument after script name
    const searchString = process.argv[3];
    const searchSelection = process.argv[4];

    // 2. Fetch & Display (The "Top 5" Logic)
    const cardsUrl = `https://api.trello.com/1/lists/${trelloSettings.todoListId}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}&fields=name,desc,labels,pos&limit=50&filter=open`;
    const cardsRes = await fetch(cardsUrl);

    if (!cardsRes.ok) {
      console.error(`Trello API error fetching cards: ${cardsRes.status} ${cardsRes.statusText}`);
      process.exit(1);
    }

    const fetchedCards = await cardsRes.json();
    // Sort by pos ascending and take the first 5
    const cards = fetchedCards.sort((a, b) => a.pos - b.pos).slice(0, 5);

    if (!selectionArg) {
      let selectionPrompt = "--- todo (top 5) ---\n";
      cards.forEach((card, index) => {
        selectionPrompt += `[${index + 1}] ${card.name}\n`;
        if (card.labels && card.labels.length > 0) {
          const labelNames = card.labels.map(l => l.name).filter(n => n).join(" | ");
          if (labelNames) {
            selectionPrompt += `    ${labelNames}\n`;
          }
        }
      });
      selectionPrompt += "[6] Search for a card\n";
      selectionPrompt += "\nChoose a card (1-5 to select, 6 to search, or 0 to cancel): ";

      // Output the selection prompt for Gemini to handle
      console.log(JSON.stringify({ status: "success", message: selectionPrompt }));
      return;
    }

    if (selectionArg === '0') {
      console.log(JSON.stringify({ status: "cancelled", message: "Trello card selection cancelled." }));
      return;
    }

    let targetCard;

    if (selectionArg === '6') {
      if (!searchString) {
        console.log(JSON.stringify({ status: "search_required", message: "Enter search string: " }));
        return;
      }

      const boardCardsUrl = `https://api.trello.com/1/boards/${trelloSettings.boardId}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}&fields=name,desc,labels`;
      const boardCardsRes = await fetch(boardCardsUrl);
      if (!boardCardsRes.ok) {
        console.error(`Trello API error fetching board cards: ${boardCardsRes.status} ${boardCardsRes.statusText}`);
        process.exit(1);
      }
      const allCards = await boardCardsRes.json();
      const matchedCards = allCards.filter(c => c.name.toLowerCase().includes(searchString.toLowerCase()));

      if (matchedCards.length === 0) {
        console.log(JSON.stringify({ status: "error", message: `No cards found matching "${searchString}".` }));
        return;
      }

      if (!searchSelection) {
        let searchPrompt = `--- search results for "${searchString}" ---\n`;
        matchedCards.forEach((card, index) => {
          searchPrompt += `[${index + 1}] ${card.name}\n`;
        });
        searchPrompt += "\nChoose a card (1-" + matchedCards.length + " to select, or 0 to cancel): ";
        console.log(JSON.stringify({ status: "success", message: searchPrompt }));
        return;
      }

      if (searchSelection === '0') {
        console.log(JSON.stringify({ status: "cancelled", message: "Trello card selection cancelled." }));
        return;
      }

      const selectedIndex = parseInt(searchSelection, 10) - 1;
      if (isNaN(selectedIndex) || selectedIndex < 0 || selectedIndex >= matchedCards.length) {
        console.error(`Invalid selection. Please enter a number between 1 and ${matchedCards.length} (or 0 to cancel).`);
        process.exit(1);
      }
      targetCard = matchedCards[selectedIndex];
    } else {
      const selectedIndex = parseInt(selectionArg, 10) - 1;

      if (isNaN(selectedIndex) || selectedIndex < 0 || selectedIndex >= cards.length) {
        console.error("Invalid selection. Please enter a number between 1 and 5 (or 0 to cancel).");
        process.exit(1);
      }

      targetCard = cards[selectedIndex];
    }

    // Move card to "in dev" list
    const moveCardUrl = `https://api.trello.com/1/cards/${targetCard.id}?key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}&idList=${trelloSettings.inDevListId}`;
    const moveCardRes = await fetch(moveCardUrl, { method: "PUT" });

    if (!moveCardRes.ok) {
      console.error(`Trello API error moving card: ${moveCardRes.status} ${moveCardRes.statusText}`);
      process.exit(1);
    }

    const cardContext = `Trello Card Name: ${targetCard.name}\nTrello Card Description:\n${targetCard.desc || "No description provided."}`;

    console.log(`------\n\nCard "${targetCard.name}" moved to "in dev", starting...\n\n\n------`);

    console.log(JSON.stringify({
      status: "success",
      message: `Card "${targetCard.name}" moved to "in dev", starting...`,
      cardContext: cardContext,
      details: { cardId: targetCard.id, cardName: targetCard.name, newList: "in dev" }
    }));

  } catch (err) {
    console.error(`Error processing Trello card: ${err.message || err}`);
    process.exit(1);
  }
}

trelloStartCard();
