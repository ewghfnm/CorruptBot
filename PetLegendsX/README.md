# Pet Legends X — 3-File Setup

A Roblox pet simulator MVP packed into just **3 files**. No folders, no nesting, no Rojo. Paste, play.

---

## Files

| File | Where it goes | What kind of script |
|------|---------------|---------------------|
| `PetLegendsX_Shared.lua` | `ReplicatedStorage` | **ModuleScript** named `PetLegendsX_Shared` |
| `PetLegendsX_Server.lua` | `ServerScriptService` | **Script** (regular Script) |
| `PetLegendsX_Client.lua` | `StarterPlayer` → `StarterPlayerScripts` | **LocalScript** |

---

## Setup steps

### 1. Open Roblox Studio
Open a new place (or your existing one).

### 2. Enable API services
**File → Game Settings → Security:**
- Turn ON **Enable Studio Access to API Services** (so DataStore works while testing)

### 3. Create the Shared module
1. In Explorer, right-click `ReplicatedStorage` → **Insert Object** → **ModuleScript**
2. Rename it to **exactly** `PetLegendsX_Shared` (this name matters!)
3. Open it, delete the default code, and paste the entire contents of `PetLegendsX_Shared.lua`
4. **Before saving**, find this section near the top:
   ```lua
   ADMIN_USERNAMES = {
       -- "YourRobloxUsername",
   },
   ```
   Uncomment the line and replace with your Roblox username (or add your UserId to `ADMIN_USER_IDS` instead). Save.

### 4. Create the Server script
1. Right-click `ServerScriptService` → **Insert Object** → **Script**
2. Name it whatever you want (e.g. `PetLegendsX_Server`)
3. Open it, delete the default code, paste `PetLegendsX_Server.lua`. Save.

### 5. Create the Client script
1. In Explorer, expand `StarterPlayer` → right-click `StarterPlayerScripts` → **Insert Object** → **LocalScript**
2. Name it whatever you want (e.g. `PetLegendsX_Client`)
3. Open it, delete the default code, paste `PetLegendsX_Client.lua`. Save.

### 6. Press Play
You should see:
- HUD at the top with Coins / Gems / Rebirths
- Side buttons: **Pets**, **Eggs**, **Worlds**, **Rebirth**, **Shop**
- Orange breakable crates spawning across worlds
- (If you set yourself as admin) an **ADMIN** button on the side, or press **F4**

---

## Quick controls

| Action | How |
|--------|-----|
| Break crates | Stand near them — pets attack automatically |
| Hatch egg | Open **Eggs** menu, click Hatch 1 / Hatch 3 / Auto |
| Equip pet | Open **Pets**, click **Equip** on a card |
| Unlock world | Open **Worlds**, click **Unlock** (need coins + rebirth count) |
| Rebirth | Open **Rebirth**, click button (resets coins+worlds, gives multiplier) |
| Buy gamepass | Open **Shop**, click price (only works after you set real gamepass IDs) |
| Open admin panel | Click side **ADMIN** button or press **F4** |

---

## Admin panel — what it does

All commands are **server-validated** (clients can't spoof). Open with the **ADMIN** side button or **F4**.

- **Currency:** Give/Set Coins, Give/Set Gems
- **Give Pet:** by `petId` (e.g. `meadow_dog`) + tier (`Standard`/`Golden`/`Rainbow`/`DarkMatter`) + optional mutation
- **Quick Huge buttons** for each Huge pet
- **Force Hatch** any egg, any number of times
- **Gamepasses:** Grant or Revoke any gamepass without paying Robux
- **Set Rebirths**, **Unlock All Worlds**, **Announce**, **Kick**

The `Target` field at the top lets you target another player by Username or UserId. Leave it blank to target yourself.

---

## What's included

- 60+ pets across 12 worlds
- 11 rarities: Common, Uncommon, Rare, Epic, Legendary, Mythical, Secret, Divine, Exclusive, **Huge**, Admin
- 6 Huge pets (1 in 5,000,000 chance)
- Eggs with weighted RNG, pity guarantees, lucky multipliers
- Mutations (1% roll: shiny / glowing / corrupted / celestial / void / infernal)
- Tiers: Standard / Golden (2x) / Rainbow (5x) / DarkMatter (10x)
- Pet leveling from breaking
- Rebirth with permanent multiplier, world unlock progression
- Server-wide announcements on rare/Huge hatches
- DataStore saving with autosave + shutdown protection
- Auto-hatch, Triple-hatch, Lucky x2, Extra Equip, VIP, Faster Walk gamepass framework
- Full HUD + Eggs/Pets/Worlds/Rebirth/Shop/Admin UI
- Hatch reveal animation
- Equipped pets visually orbit the player

---

## Customizing

All editing happens in `PetLegendsX_Shared` (just open the ModuleScript in Studio):

- **Become admin:** `Config.ADMIN_USER_IDS` or `Config.ADMIN_USERNAMES`
- **Tune balance:** `Config.PITY_*`, `Config.REBIRTH_*`, `Config.STARTING_*`
- **Hook real gamepasses:** `GamepassDatabase` — replace each `id = 0` with your real gamepass ID
- **Add/edit pets:** `PetDatabase.List` — just add new entries with unique `id`
- **Add/edit eggs:** `EggDatabase.List`
- **Add/edit worlds:** `WorldDatabase.List`
- **Add custom pet models:** create a Folder named `PetModels` in `ReplicatedStorage`, put a Model inside named exactly the pet's `id` (e.g. `meadow_dog`), with a `PrimaryPart` set. The client will use it automatically.

---

## What's NOT included (TODO if you want them later)

These were intentionally cut to keep scope tight. Each can be layered on top without rewriting the core:
- Trading & marketplace
- Clans / clan boss raids
- Quests / achievements / titles
- AFK zone, login streaks, hourly merchant
- Fusion (5 pets → upgraded version)
- Real built world maps (the spawner places simple boxes for each world)
- Sound design / full VFX
- Anti-exploit hardening beyond per-player rate limiting
- Mobile-tuned UI tweaks

---

## Common gotchas

- **DataStore won't save in Studio?** Make sure *Enable Studio Access to API Services* is on in Game Settings.
- **No admin button?** Did you put your username in `ADMIN_USERNAMES` (case-insensitive) **before** pressing Play? You need to rejoin after editing.
- **Gamepass buttons say "Set ID in DB!"?** That's intentional — the placeholder `id = 0` won't open Roblox's purchase prompt. Replace with real IDs from the creator dashboard.
- **The 3 names matter:** `PetLegendsX_Shared` is referenced by both other scripts via `WaitForChild("PetLegendsX_Shared")`. If you rename it, update both other files.
