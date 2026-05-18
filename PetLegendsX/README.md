# Pet Legends X

A pet simulator MVP for Roblox: pets, eggs, hatching, worlds, breakables, currency, rebirth, gamepasses, full admin panel.

> **Status:** Working MVP foundation, not a finished game. See "What's included / what's not" below.

---

## Project layout

```
PetLegendsX/
├── default.project.json        # Rojo project (maps folders -> Roblox services)
├── src/
│   ├── shared/                 # -> ReplicatedStorage.Shared (ModuleScripts)
│   │   ├── Config.lua
│   │   ├── Rarities.lua        # Common -> Huge -> Admin
│   │   ├── PetDatabase.lua     # All pets, including 6 Huge pets
│   │   ├── EggDatabase.lua     # Egg pools + hugeChance
│   │   ├── WorldDatabase.lua   # 12 worlds
│   │   ├── GamepassDatabase.lua# Replace IDs with your real gamepass IDs
│   │   ├── EnchantDatabase.lua
│   │   ├── Remotes.lua
│   │   ├── Util.lua
│   │   └── Signal.lua
│   ├── server/                 # -> ServerScriptService.Server
│   │   ├── init.server.lua     # Boot script (Script)
│   │   ├── DataService.lua     # DataStore + autosave + session save
│   │   ├── CurrencyService.lua
│   │   ├── PetService.lua      # Inventory, equip, level, stat compute
│   │   ├── EggService.lua      # Hatching, pity, mutations, Huge rolls
│   │   ├── BreakingService.lua # Spawns breakables, handles damage
│   │   ├── RebirthService.lua
│   │   ├── GamepassService.lua # Real MarketplaceService + admin grant
│   │   ├── AdminService.lua    # All admin commands (server-validated)
│   │   └── AnnouncementService.lua
│   └── client/                 # -> StarterPlayer.StarterPlayerScripts.Client
│       ├── init.client.lua     # Boot (LocalScript)
│       ├── HUD.lua
│       ├── EggUI.lua
│       ├── InventoryUI.lua
│       ├── WorldsUI.lua
│       ├── RebirthUI.lua
│       ├── ShopUI.lua
│       ├── AdminUI.lua         # Visible only to admins
│       ├── HatchAnimation.lua
│       ├── Notifications.lua
│       ├── PlayerData.lua
│       ├── PetFollow.lua
│       ├── Breaking.lua
│       └── UIBuilder.lua
```

---

## Setup option A — Rojo (recommended)

Rojo syncs files on disk into Roblox Studio.

1. Install Rojo: https://rojo.space/docs/v7/getting-started/installation/
   - Roblox Studio plugin **and** the `rojo` CLI (or VS Code extension).
2. In a terminal, from the `PetLegendsX/` folder:
   ```bash
   rojo serve
   ```
3. In Studio, open a new place. Open the Rojo plugin, click **Connect**.
4. Press Play. The HUD, eggs, breakables and admin (if you're listed) all show up.

---

## Setup option B — Manual (no tools needed)

If you don't want to install Rojo, recreate this structure by hand in Studio.

### 1. Create the folders/scripts

**ReplicatedStorage:**
- Add a `Folder` named `Shared`.
- Inside `Shared`, add a `ModuleScript` for each file in `src/shared/` (same name, paste contents).

**ServerScriptService:**
- Add a `Folder` named `Server`.
- Inside `Server`, add a regular `Script` named `init` and paste the contents of `src/server/init.server.lua`.
- For every other file in `src/server/`, add a `ModuleScript` with the same name.

**StarterPlayer > StarterPlayerScripts:**
- Add a `Folder` named `Client`.
- Inside `Client`, add a `LocalScript` named `init` and paste the contents of `src/client/init.client.lua`.
- For every other file in `src/client/`, add a `ModuleScript` with the same name.

### 2. Enable required Studio settings

- **Game Settings > Security > Allow HTTP Requests:** ON (DataStore safety).
- **Game Settings > Security > Enable Studio Access to API Services:** ON (so DataStore works in Studio).

### 3. Test

- Press Play. You should see the HUD, breakable crates spawning, the egg menu, etc.

---

## Configuring it

### Become an admin

Edit `src/shared/Config.lua`:
```lua
Config.ADMIN_USER_IDS = { 1234567890 }       -- your Roblox UserId
Config.ADMIN_USERNAMES = { "YourUsername" }  -- or your Roblox username
```
When you join, an `ADMIN` button appears on the side, or press **F4**.

### Hook up real gamepasses

Edit `src/shared/GamepassDatabase.lua`. Each entry has `id = 0`. Create gamepasses on the Roblox creator dashboard and paste each gamepass ID in.

### Tune the economy

`src/shared/Config.lua`:
- `STARTING_COINS`, `STARTING_GEMS`
- `PITY_LEGENDARY_AFTER`, `PITY_MYTHICAL_AFTER`
- `REBIRTH_BASE_COST`, `REBIRTH_COST_SCALE`, `REBIRTH_MULTIPLIER`

`src/shared/EggDatabase.lua`:
- `cost`, `pets[]` weights, `hugeChance` (default 1 in 5,000,000)

`src/shared/PetDatabase.lua`:
- Add as many pets as you want. Just give each a unique `id`.

### Add visual pet models (optional)

By default, equipped pets are rendered as colored neon parts orbiting the player.
To use real models:
1. In `ReplicatedStorage`, add a `Folder` named `PetModels`.
2. For each pet `id` in `PetDatabase.lua`, add a `Model` named exactly the same id (e.g. `meadow_dog`). Make sure each model has a `PrimaryPart`.
3. The client will automatically clone that model instead of using the placeholder part.

---

## Admin panel — what it does

Open with the side button or **F4**. All actions hit `AdminService` on the server, which validates that the sender is in `ADMIN_USER_IDS` / `ADMIN_USERNAMES`. Clients can't spoof.

- **Currency:** Give/Set Coins, Give/Set Gems
- **Give Pet:** by `petId` + tier (Standard/Golden/Rainbow/DarkMatter) + optional mutation
- **Quick Huge buttons** for each Huge pet
- **Force Hatch:** by egg id + count
- **Gamepasses:** Grant or Revoke any gamepass key (works without paying Robux)
- **Set Rebirths**, **Unlock All Worlds**, **Announce**, **Kick**

Target field: leave blank for yourself, or enter a Roblox username/UserId.

---

## What's included

- 60+ pets across 12 worlds, including 6 **Huge** pets
- 11 rarities: Common, Uncommon, Rare, Epic, Legendary, Mythical, Secret, Divine, Exclusive, **Huge**, Admin
- Eggs with weighted RNG, pity guarantees, Lucky gamepass multipliers
- Mutations (1% roll: shiny / glowing / corrupted / celestial / void / infernal)
- Tiers: Standard / Golden (2x) / Rainbow (5x) / DarkMatter (10x)
- Pet leveling (XP from breaking) with stat scaling
- World unlocks gated by coins + rebirth count
- Rebirth system with permanent multiplier
- Server-wide announcements on rare/Huge hatches
- Auto-hatch (gamepass), Triple-hatch (gamepass), Extra Equip (gamepass), Lucky / Ultra Lucky, VIP, Faster Walk
- DataStore save with autosave + BindToClose protection
- HUD, Eggs UI, Pets UI, Worlds UI, Rebirth UI, Shop UI, Admin UI
- Hatch reveal animation
- Notifications + server announce toasts
- Equipped pets visually orbit the player

## What's NOT included (TODO for a full game)

These are intentional scope cuts so the core is solid first. Each is straightforward to add on top:
- Trading & marketplace (needs careful anti-scam UX + server validation)
- Clans / clan boss raids
- Quests (daily / weekly / story)
- Achievements / titles
- AFK zone, login streaks, hourly merchant
- Fusion (5 pets -> upgraded version)
- Enchant rolling/applying mechanics (data structure exists in PetService stat calc)
- Built world maps (the breakable spawner makes simple boxes; replace with real builds)
- Sound design and full VFX
- Anti-exploit hardening beyond per-player rate limiting
- Mobile-tuned UI tweaks

---

## Notes & gotchas

- DataStore only works in real Studio sessions with API Services enabled, or in-game. In offline mode the save is silently skipped.
- The breakable spawner places simple parts at `(worldOrder * 200, 5, 0)` so each world is offline-testable. Replace `BreakingService.makeBreakable` calls with real placed Models in production.
- `Remotes.IsAdmin` is invoked once at client boot; if you change `Config.ADMIN_USER_IDS` you'll need to rejoin to get the admin button.
- All server logic uses player data through `DataService:Get(player)`; never write to that table from outside services without calling `DataService:MarkDirty`.
