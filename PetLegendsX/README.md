# Pet Legends X

A Roblox pet simulator MVP packed into **3 paste-and-go files**. No folders, no Rojo, no nested ModuleScripts. Open Studio → paste 3 scripts → press Play.

---

## TL;DR

| File | Where it goes | Type |
|------|---------------|------|
| `PetLegendsX_Shared.lua` | `ReplicatedStorage` | **ModuleScript** named **`PetLegendsX_Shared`** |
| `PetLegendsX_Server.lua` | `ServerScriptService` | **Script** (regular Script) |
| `PetLegendsX_Client.lua` | `StarterPlayer` → `StarterPlayerScripts` | **LocalScript** |

⚠️ The ModuleScript in ReplicatedStorage **must** be named `PetLegendsX_Shared` exactly. The Server and Client scripts can be named anything.

---

# 📖 Tutorial — From Zero to Playing

This walkthrough takes ~5 minutes if you've never touched Studio before.

## Step 1 — Get Roblox Studio open

1. Download/install Roblox Studio from [create.roblox.com](https://create.roblox.com) if you don't have it.
2. Open Studio. Click **New** → pick the **Baseplate** template (or any template — we'll be replacing the world anyway).
3. You should see an empty grey baseplate with the camera looking down at it.

## Step 2 — Turn on DataStore for testing

1. Top menu: **File → Game Settings**
2. Click the **Security** tab on the left.
3. Find **Enable Studio Access to API Services** and turn it **ON**.
4. Click **Save**. (If you don't do this, your coins/pets won't persist between play sessions.)

## Step 3 — Find the Explorer panel

The Explorer is the panel that lists all the objects in your game. If you can't see it:

- Top menu: **View** → click **Explorer** to toggle it on.

You should now see a side panel with stuff like `Workspace`, `Players`, `Lighting`, `ReplicatedStorage`, `ServerScriptService`, `StarterPlayer`, etc.

## Step 4 — Create the Shared module ⚠️ Most important step

This is the only one where the name matters.

1. In Explorer, find **`ReplicatedStorage`** (might need to scroll).
2. **Hover** over `ReplicatedStorage` — a small **`+`** button appears on the right side. Click it.
3. In the popup, search for and click **`ModuleScript`**.
4. A new ModuleScript appears under ReplicatedStorage, probably called `ModuleScript`.
5. **Click the name once** to rename it. Type exactly: `PetLegendsX_Shared`
   - Capital P, capital L, capital X, underscore, capital S. Spelling matters!
6. Double-click the script to open the code editor.
7. Select all the default code (`Ctrl+A` / `Cmd+A`) and delete it.
8. Open `PetLegendsX_Shared.lua` from this repo, copy **all** of its contents, and paste into the Studio editor.

Before saving, scroll near the top until you find:
```lua
ADMIN_USERNAMES = {
    -- "YourRobloxUsername",
},
```
Remove the `--` from the second line and replace with your Roblox username:
```lua
ADMIN_USERNAMES = {
    "MyCoolUsername123",
},
```
This makes you an admin so you can use the in-game admin panel for testing.

Save by pressing `Ctrl+S` (or just close the script tab).

## Step 5 — Create the Server script

1. Hover over **`ServerScriptService`** → click the **`+`** → click **`Script`**.
2. The new script can be named anything (e.g. `PetLegendsX_Server`). You don't need to rename it.
3. Double-click to open it. Delete the default code.
4. Copy all of `PetLegendsX_Server.lua` from this repo and paste it in. Save.

## Step 6 — Create the Client script

1. In Explorer, expand **`StarterPlayer`** by clicking the arrow next to it.
2. You'll see `StarterPlayerScripts` and `StarterCharacterScripts`. Hover over **`StarterPlayerScripts`** → **`+`** → **`LocalScript`**.
   - It MUST be a LocalScript, not a regular Script. They're different things.
3. The new LocalScript can be named anything (e.g. `PetLegendsX_Client`).
4. Double-click to open. Delete default code.
5. Copy all of `PetLegendsX_Client.lua` from this repo and paste it in. Save.

## Step 7 — Press Play

Top menu: **Home** tab → click the big blue **▶ Play** button (or press `F5`).

Wait 2–5 seconds. You should see:

- ✅ A **green spawn pad** in the middle of a **green grassy field** (Spawn Meadow)
- ✅ Top of screen: 3 stat bars showing **Coins**, **Gems**, **Rebirths**
- ✅ Left side: 5 colored buttons — **Pets**, **Eggs**, **Worlds**, **Rebirth**, **Shop**
- ✅ A red **ADMIN** button below them (only if you set yourself as admin in Step 4)
- ✅ Orange/themed **breakable crates** in a circle around the world
- ✅ A glowing **golden egg vendor pad** in front of the spawn point with a giant "Meadow Egg" sign floating above it
- ✅ A colored **teleporter pad** to the right leading to the next world (Candy Kingdom)

If you don't see all this, scroll down to **Troubleshooting**.

## Step 8 — Play the game

Walk around with WASD. The basic loop:

1. **Get coins:** Walk near the orange crates. Your starter pets will auto-attack them. Each crate destroyed gives coins (+ rare gem chance).
2. **Hatch your first pet:** Walk onto the **glowing golden egg vendor pad** in front of spawn. As long as you have 100 coins, it'll auto-hatch every 0.6 seconds. Each pet drops with a flashy reveal.
3. **Equip the pets:** Press the **Pets** side button. Click **Equip** on your best ones (max 3 by default).
4. **Save up coins** until you can afford the next world (Candy Kingdom = 25,000 coins). The **Worlds** menu shows costs.
5. **Travel:** Walk onto the colored teleporter pad on the edge of any world. It zaps you to the next/previous world (only if unlocked).
6. **Rebirth** when you've maxed a world (open the Rebirth menu) — costs all your coins but gives a permanent multiplier and unlocks higher worlds.

### What the buttons do

| Button | Opens |
|--------|-------|
| **Pets** | Your pet inventory. Equip / unequip / lock / delete pets. Searchable. |
| **Eggs** | Full egg menu. Hatch 1, Hatch 3 (gamepass), Auto (gamepass). Shows odds. |
| **Worlds** | World list with unlock buttons. Shows cost and rebirth requirement. |
| **Rebirth** | Confirms your rebirth (resets coins+worlds, gives multiplier). |
| **Shop** | List of all gamepasses. Purchase prompts (placeholder until you set IDs). |
| **ADMIN** | Admin panel (or press F4). |

---

## 🛠 Admin Panel — what each button does

The ADMIN button is only visible if your Roblox username (or UserId) is in `Config.ADMIN_USERNAMES` / `ADMIN_USER_IDS`.

All admin actions are **server-validated** — even if a hacker fakes the button, the server will reject the command.

| Section | What it does |
|---------|--------------|
| **Target** field | Username or UserId. Leave blank to target yourself. |
| **Currency** | Give/Set Coins or Gems. Useful for testing balance. |
| **Give Pet** | Type a pet `id` (e.g. `meadow_dog`, `dino_t_rex`). Optionally specify tier (`Standard`/`Golden`/`Rainbow`/`DarkMatter`) and mutation. |
| **Quick Huge buttons** | One-click give yourself any of the 18 Huge pets. |
| **Force Hatch** | Type an egg id + count. Or click any of the named egg buttons to hatch 1 free. |
| **Gamepasses** | Grant or Revoke any gamepass with no Robux cost — for testing. |
| **Set Rebirths** | Set your rebirth count to any number. |
| **Unlock All Worlds** | Instant access to every world. |
| **Announce** | Send a server-wide red toast. |
| **Kick** | Kicks the target with a custom reason. |

---

## 🌍 What's in the world

**24 themed worlds** are auto-generated when the server starts:

1. **Spawn Meadow** — green grass, your starting world
2. **Jungle Ruins** — tropical trees, wild animals
3. **Candy Kingdom** — pink sweet land
4. **Desert Sun Dunes** — scorching sand
5. **Cyber City** — neon dark metal grid
6. **Volcano Core** — slate red, lava themed
7. **Pirate Cove** — wooden harbor, ghost ships
8. **Ocean Paradise** — sandy beach, sea creatures
9. **Steampunk City** — brass and copper
10. **Frozen Peaks** — ice and snow
11. **Mushroom Glade** — surreal fungi forest
12. **Ancient Egypt** — golden pyramids
13. **Faerie Forest** — magical pastel
14. **Space Station** — outer space
15. **Crystal Caves** — gemstone glow
16. **Samurai World** — cherry blossom temples
17. **Storm Realm** — lightning sky
18. **Heaven Realm** — marble white
19. **Dino Land** — prehistoric jungle
20. **Robot Factory** — industrial steel
21. **Void Realm** — dark corruption
22. **Underworld** — hellscape (gem cost)
23. **Cosmic Infinity** — galaxy endgame
24. **Eternity** — final world (50 rebirths required)

Each world has:
- A **themed baseplate** (color/material matches the theme)
- **20 random decorative props** (themed pillars, structures, glowing crystals)
- A giant **glowing world-name billboard**
- One **egg vendor pad per egg in that world** (auto-hatches when you stand on it)
- **Themed breakable crates** in a circle around the center
- **Teleporter pads** at the edges connecting to the next/previous world

## 🥚 Eggs are on the map

You don't have to open a menu to hatch. Each world has **glowing golden vendor pads** on the ground with a 3D egg model and a floating sign. Walk onto one and it auto-hatches that egg every 0.6 seconds (until you run out of currency or step off).

The **Eggs menu** still works for browsing the full list, seeing odds, multi-hatching (gamepass), and Auto-hatch (gamepass).

## 🐾 200+ pets

11 rarities: **Common**, Uncommon, Rare, Epic, Legendary, Mythical, Secret, Divine, Exclusive, **Huge**, Admin

- **18 Huge pets** (1 in 5,000,000 chance) — server-wide announcement when hatched
- 4 tiers per pet: Standard / Golden (2x) / Rainbow (5x) / DarkMatter (10x)
- 6 mutations: shiny / glowing / corrupted / celestial / void / infernal
- Pity system: guaranteed Legendary every 75 hatches, Mythical every 250

---

## ⚙️ Customizing

Open the `PetLegendsX_Shared` ModuleScript in Studio. Everything is in one file:

| What | Where |
|------|-------|
| Become admin | `Config.ADMIN_USER_IDS` / `ADMIN_USERNAMES` |
| Tune pity rates | `Config.PITY_LEGENDARY_AFTER`, `Config.PITY_MYTHICAL_AFTER` |
| Tune rebirth | `Config.REBIRTH_BASE_COST`, `REBIRTH_COST_SCALE`, `REBIRTH_MULTIPLIER` |
| Tune starting cash | `Config.STARTING_COINS`, `STARTING_GEMS` |
| Hook real gamepass IDs | `GamepassDatabase` — replace each `id = 0` with the real ID from your creator dashboard |
| Add a pet | Add a new entry to `PetDatabase.List` with a unique `id` |
| Add an egg | Add a new entry to `EggDatabase.List` |
| Add a world | Add a new entry to `WorldDatabase.List` (theme color + material + decor colors) |
| Use real pet models | Create a `Folder` named `PetModels` in `ReplicatedStorage`, put a `Model` inside named exactly the pet's `id` (e.g. `meadow_dog`). Make sure each model has a `PrimaryPart`. The client clones it instead of using a placeholder neon part. |

---

## 🚧 Troubleshooting

**Q: I see no UI when I press Play.**
- Check that the LocalScript is in `StarterPlayerScripts`, NOT `StarterScripts` or `StarterCharacterScripts`.
- Look at the Output window (bottom of Studio). Any red errors will tell you what's missing.
- Make sure all 3 scripts are pasted in completely (no truncation).

**Q: The game prints `[PetLegendsX_Shared] not found` or similar.**
- Your ModuleScript in ReplicatedStorage isn't named exactly `PetLegendsX_Shared`. Capitalization matters.

**Q: Coins don't save between play sessions.**
- Game Settings → Security → **Enable Studio Access to API Services** must be ON. DataStore needs API access.

**Q: I don't see the ADMIN button.**
- You need to set `ADMIN_USERNAMES` (case-insensitive) **before** pressing Play. Stop the playtest, edit the Shared module, then play again.
- Use exactly the username Roblox shows you (no display name, no @ symbol).

**Q: Gamepass buttons say "Set ID in DB!"**
- That's intentional. The placeholder `id = 0` doesn't link to a real Roblox gamepass. Create gamepasses on your creator dashboard, copy each ID, and paste them into `GamepassDatabase` in the Shared module.

**Q: The world looks weird / clips through itself.**
- The procedural world generator places things randomly. Stop the game (▶ → ⬛), then in the Workspace explorer find the `PetLegendsX_Worlds` folder and right-click → Delete it. Press Play again to regenerate.

**Q: How do I get to the Underworld / Eternity worlds?**
- Underworld costs 2,000 **gems** (not coins) and 28 rebirths. Eternity costs 50,000 gems and 50 rebirths. Use the admin panel for testing.

**Q: I want to publish this to Roblox.**
- Top menu: **File → Publish to Roblox**. Sign in to your Roblox account when prompted. The game saves to your account and you can configure visibility/monetization on the [creator dashboard](https://create.roblox.com).

---

## ❌ What's intentionally NOT included

To keep scope sane, these are NOT in this drop. Each is a meaningful project on its own:

- Trading / marketplace (high anti-scam complexity)
- Clans / clan boss raids
- Quests / achievements / titles / leaderboards
- AFK rewards zone, login streaks, hourly merchant
- Pet fusion (5-of-same → upgraded)
- **Hand-built world maps** (the procedural builder gives playable themed worlds; replacing them with detailed scenery is a builder/artist job — beyond what code generation can do well)
- Sound design / full VFX
- Anti-exploit hardening beyond per-player rate limiting
- Mobile-tuned UI tweaks

---

## ⚠️ Honest expectations

This is a strong **MVP foundation** — every system works, the game is playable end-to-end, and the architecture supports the missing features. It's not a finished, polished, ready-to-launch competitor to Pet Sim X. That kind of game is months of full-time team work.

What you have here is enough to:
- Demo the gameplay loop
- Test economy balance
- Show to a builder/artist as a starting point
- Iterate on systems before committing to art and content investment

Have fun! 🐾
