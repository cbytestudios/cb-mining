# cb-mining

## Overview
The `cb-mining` resource implements a sophisticated mining system for the RSG Framework, designed for RedM servers. It supports multiple mining activities (pickaxe mining, dynamite mining, gold panning, and prospecting) with configurable locations, required items, and rewards. The system integrates with the `cb-skills` resource for skill progression (mining, smelting, prospecting) and includes a unique lantern helmet feature that provides dynamic lighting, requiring fuel. Data is persisted using the `cb-skills` database and RSG-Core metadata, with saves on logout and periodic intervals.

## Features
- Configurable mining spots for pickaxe mining, dynamite mining (with explosion risk), and gold panning.
- Prospecting system to survey for minerals with configurable rewards.
- Smelting system to process ores into ingots, requiring fuel.
- Integration with `cb-skills` for XP and level progression.
- Lantern helmet with dynamic lighting, consuming fuel over time.
- Random events during mining (e.g., rare finds, cave-ins, animal attacks).
- Optimized inventory checks using `rsg-inventory`.

## Dependencies
- `rsg-core`: Required for core framework functionality, player management, and notifications.
- `cb-skills`: Required for skill progression and persistence.
- `oxmysql`: Required for database operations (via `cb-skills`).
- `rsg-inventory`: Required for inventory management and item checks.

## Installation
1. **Add Resource to Server**:
   - Place the `cb-mining` folder in your server's `resources` directory.
   - Add `ensure cb-mining` to your `server.cfg`, ensuring `cb-skills` starts first.

2. **Configuration**:
   - Edit `config.lua` to customize mining, smelting, and prospecting spots, including coordinates, required items, rewards, and associated skills.
   - Configure the lantern helmet settings (fuel item, duration, light properties) in `config.lua`.

3. **Items for rsg-inventory**:
   - Add the following items to your `rsg-inventory` items table (typically in the database or inventory configuration file):
     ```json
     [
         {"name": "pickaxe", "label": "Pickaxe", "weight": 2.0, "type": "item", "description": "A tool for mining rocks."},
         {"name": "dynamite", "label": "Dynamite", "weight": 0.5, "type": "item", "description": "Explosive for mining."},
         {"name": "goldpan", "label": "Gold Pan", "weight": 1.0, "type": "item", "description": "A pan for gold panning in rivers."},
         {"name": "prospector_tool", "label": "Prospector Tool", "weight": 1.5, "type": "item", "description": "A tool for surveying minerals."},
         {"name": "lantern_helmet", "label": "Lantern Helmet", "weight": 1.0, "type": "item", "description": "A helmet with a fueled lantern for illumination."},
         {"name": "lamp_oil", "label": "Lamp Oil", "weight": 0.3, "type": "item", "description": "Fuel for the lantern helmet."},
         {"name": "stone", "label": "Stone", "weight": 0.5, "type": "item", "description": "Raw stone from mining."},
         {"name": "iron_ore", "label": "Iron Ore", "weight": 0.7, "type": "item", "description": "Raw iron ore from mining."},
         {"name": "coal", "label": "Coal", "weight": 0.4, "type": "item", "description": "Coal used as fuel or from mining."},
         {"name": "gold_nugget", "label": "Gold Nugget", "weight": 0.2, "type": "item", "description": "A small gold nugget."},
         {"name": "gold_dust", "label": "Gold Dust", "weight": 0.1, "type": "item", "description": "Fine gold dust from panning."},
         {"name": "small_nugget", "label": "Small Nugget", "weight": 0.15, "type": "item", "description": "A small gold nugget from panning."},
         {"name": "large_gold_nugget", "label": "Large Gold Nugget", "weight": 0.3, "type": "item", "description": "A rare large gold nugget."},
         {"name": "mineral_sample", "label": "Mineral Sample", "weight": 0.3, "type": "item", "description": "A sample from prospecting."},
         {"name": "rare_mineral", "label": "Rare Mineral", "weight": 0.2, "type": "item", "description": "A rare mineral from prospecting."},
         {"name": "diamond", "label": "Diamond", "weight": 0.1, "type": "item", "description": "A rare diamond from prospecting."},
         {"name": "iron_ingot", "label": "Iron Ingot", "weight": 1.0, "type": "item", "description": "Smelted iron ingot."},
         {"name": "gold_bar", "label": "Gold Bar", "weight": 1.2, "type": "item", "description": "Smelted gold bar."},
         {"name": "rare_gem", "label": "Rare Gem", "weight": 0.1, "type": "item", "description": "A rare gem found during mining."}
     ]
     ```
   - Ensure these items are added to the `items` table or inventory configuration as per your `rsg-inventory` setup.

4. **Database**:
   - No additional database setup is required for `cb-mining`, as it relies on `cb-skills` for skill persistence.

## Usage
- **Mining**:
  - Players can mine at configured spots using a pickaxe, dynamite, or gold pan, earning `mining` skill XP.
  - Dynamite mining includes a risk of misfire, causing damage.
- **Smelting**:
  - Players can smelt ores into ingots at smelting spots, requiring coal as fuel and earning `smelting` skill XP.
- **Prospecting**:
  - Players use a prospector tool to survey minerals, earning `prospecting` skill XP.
- **Lantern Helmet**:
  - Players can equip a lantern helmet (usable item) for dynamic lighting, consuming lamp oil over time.
- **Random Events**:
  - Mining activities may trigger random events like rare finds, cave-ins, or animal attacks.

## Server Configuration
Add to `server.cfg`:
```cfg
ensure cb-mining

```

## Notes
- Coordinates and animations in `config.lua` are placeholders and should be tested and adjusted in-game.
- The `HasItem` function uses `rsg-inventory` callbacks for accurate inventory checks.
- The `DrawText3D` function may require a custom implementation or a third-party library.
- Ensure items are properly registered in `rsg-inventory` before use.

## Support
For issues or feature requests, contact the developer through the project's repository or community forums.
