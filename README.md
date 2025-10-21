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
   - Add the following items to your `rsg-inventory` file:
     ```lua
     pickaxe = { name = 'pickaxe', label = 'Pickaxe', weight = 2.0, type = 'item', image = 'pickaxe.png', unique = false, useable = true, shouldClose = true, description = 'A tool for mining rocks' },
     dynamite = { name = 'dynamite', label = 'Dynamite', weight = 0.5, type = 'item', image = 'dynamite.png', unique = false, useable = true, shouldClose = true, description = 'Explosive for mining' },
     goldpan = { name = 'goldpan', label = 'Gold Pan', weight = 1.0, type = 'item', image = 'goldpan.png', unique = false, useable = true, shouldClose = true, description = 'A pan for gold panning in rivers' },
     prospector_tool = { name = 'prospector_tool', label = 'Prospector Tool', weight = 1.5, type = 'item', image = 'prospector_tool.png', unique = false, useable = true, shouldClose = true, description = 'A tool for surveying minerals' },
     lantern_helmet = { name = 'lantern_helmet', label = 'Lantern Helmet', weight = 1.0, type = 'item', image = 'lantern_helmet.png', unique = false, useable = true, shouldClose = true, description = 'A helmet with a fueled lantern for illumination' },
     lamp_oil = { name = 'lamp_oil', label = 'Lamp Oil', weight = 0.3, type = 'item', image = 'lamp_oil.png', unique = false, useable = true, shouldClose = true, description = 'Fuel for the lantern helmet' },
     stone = { name = 'stone', label = 'Stone', weight = 0.5, type = 'item', image = 'stone.png', unique = false, useable = false, shouldClose = true, description = 'Raw stone from mining' },
     iron_ore = { name = 'iron_ore', label = 'Iron Ore', weight = 0.7, type = 'item', image = 'iron_ore.png', unique = false, useable = false, shouldClose = true, description = 'Raw iron ore from mining' },
     coal = { name = 'coal', label = 'Coal', weight = 0.4, type = 'item', image = 'coal.png', unique = false, useable = false, shouldClose = true, description = 'Coal used as fuel or from mining' },
     gold_nugget = { name = 'gold_nugget', label = 'Gold Nugget', weight = 0.2, type = 'item', image = 'gold_nugget.png', unique = false, useable = false, shouldClose = true, description = 'A small gold nugget' },
     gold_dust = { name = 'gold_dust', label = 'Gold Dust', weight = 0.1, type = 'item', image = 'gold_dust.png', unique = false, useable = false, shouldClose = true, description = 'Fine gold dust from panning' },
     small_nugget = { name = 'small_nugget', label = 'Small Nugget', weight = 0.15, type = 'item', image = 'small_nugget.png', unique = false, useable = false, shouldClose = true, description = 'A small gold nugget from panning' },
     large_gold_nugget = { name = 'large_gold_nugget', label = 'Large Gold Nugget', weight = 0.3, type = 'item', image = 'large_gold_nugget.png', unique = false, useable = false, shouldClose = true, description = 'A rare large gold nugget' },
     mineral_sample = { name = 'mineral_sample', label = 'Mineral Sample', weight = 0.3, type = 'item', image = 'mineral_sample.png', unique = false, useable = false, shouldClose = true, description = 'A sample from prospecting' },
     rare_mineral = { name = 'rare_mineral', label = 'Rare Mineral', weight = 0.2, type = 'item', image = 'rare_mineral.png', unique = false, useable = false, shouldClose = true, description = 'A rare mineral from prospecting' },
     diamond = { name = 'diamond', label = 'Diamond', weight = 0.1, type = 'item', image = 'diamond.png', unique = false, useable = false, shouldClose = true, description = 'A rare diamond from prospecting' },
     iron_ingot = { name = 'iron_ingot', label = 'Iron Ingot', weight = 1.0, type = 'item', image = 'iron_ingot.png', unique = false, useable = false, shouldClose = true, description = 'Smelted iron ingot' },
     gold_bar = { name = 'gold_bar', label = 'Gold Bar', weight = 1.2, type = 'item', image = 'gold_bar.png', unique = false, useable = false, shouldClose = true, description = 'Smelted gold bar' },
     rare_gem = { name = 'rare_gem', label = 'Rare Gem', weight = 0.1, type = 'item', image = 'rare_gem.png', unique = false, useable = false, shouldClose = true, description = 'A rare gem found during mining' }
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
