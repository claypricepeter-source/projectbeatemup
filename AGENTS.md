# Project Beatemup — Game Design Document & Roadmap

> **This file is the source of truth for the project.** Any AI tool or human working on
> this game should read this document first, follow its conventions, and update the
> roadmap checkboxes in Section 8 as work completes. If a design decision changes,
> change it *here* first, then in the code.

---

## 0. HANDOFF STATUS (updated 2026-09-24)

**Where the project stands:** Phases 0–5 are complete and verified in-game (see
checked boxes + per-phase notes in §8). The campaign has now been extended to four
stages with a candy-factory detour and elevator finale. The original three-stage
route was fully verified; the new Stage 3/4 split requires a final human campaign
playtest after the Pages deployment.

**What runs today:** F5 launches `scenes/main.tscn` at the title screen. Start routes
through story cards into four consecutive stages: **Second Avenue at Night**
(four waves + Slick Rick), **The Sewers of Shame** (five waves + Ragnaros),
**The Nightmarish Candy Factory** (five waves + Jawbreaker), and **The Elevator
to the Penthouse** (four drop-in waves + Victor). Stages include camera locks,
props, pickups, boss bars and stage-clear tallies. Losing a life respawns in the
active fight; zero lives routes through Continue and Game Over. High score persists
in `user://save.cfg`.

**Streets of Rage 2 remake (2026-09-24):** combat, grappling, weapons, HUD,
timer and scoring were rebuilt to match SoR2 as closely as possible using
Axel's move data from the SoR2 move FAQ (full spec in §4.2). World, story, art
and stages are unchanged; no SoR2 assets, names or music are used.

**Controls:** Arrows/WASD move, Z/J attack (B), X/K jump (C), C/L special (A),
Esc pause. Gamepad: D-pad/left stick, X/Square attack, A/Cross jump,
Y/Triangle special, Start pause. Touch/Web: virtual stick plus ATTACK, JUMP,
SPECIAL and pause buttons; story/continue/clear cards show a NEXT button.
The full move list is in README.md and §4.2.

**Key facts a new agent needs (details in the sections referenced):**
- Working via the **godot-ai MCP plugin** on Godot **4.7-stable** (§9 Tooling). After
  writing .gd/.tscn/.tres files externally, call `filesystem_manage(op="scan")`,
  then run + verify with `project_run` / `game_eval` / `editor_screenshot`.
  `game_eval` code must be straight-line (no indented blocks) or it may fail to parse.
- Enemies and Stage 1 art come from the **Streets of Fight** pack (§6.2,
  CREDITS.md) and render at **2× scale**. Sean now uses the user-provided
  `clay_character_godot` set at native 1×: 256×192 canvases, supplied feet anchor
  (128, 176), and dedicated combat/KO art (§8 Phase 1 notes).
- Stage 1 is 4480×480 (seven 640 px screens), composed from
  `assets/_source_packs/streets-of-fight/Stage Layers/tileset.png`; its walkable
  band is y ∈ [204, 264], with the camera fixed at y=200. Source art remains at 2×.
- Stage 2 is 5120×480 (eight screens), with a y ∈ [204, 280] processing-floor
  plane. `harbour_stage.gd` repeats a doorless core of the keyed user-provided room
  into one tunnel and animates its 15 green frames across every open channel: the
  rear band behind the fighters and the full lower trench below the platform;
  each selected frame is deliberately stretched to the full channel depth. A seeded
  layout places smaller user-provided decals only in plain wall slots between grates,
  and twelve varied curry packages float half-submerged at randomized intervals
  throughout the lower acid channel;
  `chain_parallax.gd` moves the foreground chains 18% faster than the camera. The
  stage also requests its music cue locally so direct F6/debug launches have audio.
  The untouched sheet is retained under `assets/_source_packs/` and remains
  local-development-only pending provenance/redistribution confirmation.
- Stage 3 is a 5120×480 candy-processing floor with a y ∈ [204, 280] plane.
  `candy_factory_stage.gd` repeats the supplied factory background beneath
  candy-cane pillars and an animated hot-pink sugar-sludge channel. Jawbreaker
  reuses Slick Rick's complete boss interface with a distinct pink palette.
- Stage 4 is a fixed-width cargo elevator in `elevator_stage.gd`. The shaft scrolls
  continuously while four resource-authored waves drop onto the platform; reaching
  the penthouse stops the elevator and spawns Victor for the final battle.
- Combat rules implemented in `scripts/` match the SoR2 spec in §4.2. The
  anti-stunlock rule (3rd consecutive hit within 0.7s → knockdown) now protects
  **only the player** (`Fighter.anti_stunlock`); enemies take the full five-hit
  string, and bosses counter on the 4th quick hit (`BOSS_COUNTER_HITS`). EventBus parameters must stay untyped; Streets of Fight characters
  rotate the `hurt` frame for knockdown, while the new boss uses dedicated KO art.
  Standard Punk/Red Punk instances now use the project-generated Sikh punk atlas
  (black turban, beard, purple-gold jacket); Knife Punk, Thug and boss art remain
  separate. Enemy soft separation and per-sheet source-facing metadata are now
  implemented; keep both when adding the Phase 5 roster.
- Phase 3's reusable pieces are `WaveData`/`WaveTrigger`, `CameraDirector`, the
  breakable/pickup base scenes, and `MainFlow`. Boss-wave camera lock intentionally
  remains active while the clear tally is shown.
- Phase 4's `MainFlow` owns title/intro/pause/continue/clear/game-over/ending routing.
  `STAGE_SCENES` and `INTRO_CARDS` contain all four stages; `GameState.next_stage()`
  advances the shell, while high score is persisted immediately through `ConfigFile`.
- Phase 5 enemy variants resolve from `EnemyStats.base_variant` plus stat
  multipliers. `WaveData.enemy_stats` is an optional per-spawn override array; use
  it to mix Red Punk/Dock Thug/Park Punk resources into waves without new scenes.
- `AudioManager` is a persistent two-player music router plus an eight-player SFX
  pool. Stages 1–2 use supplied MP3s; title, Stages 3–4, boss, clear, Game Over and
  ending use distinct project-native chiptune loops synthesized at runtime. A boss
  stinger and seven small gameplay/UI cues are also synthesized at runtime. The
  supplied `deathsean.mp3` plays at the start of Sean's life-loss KO sequence;
  supplied `after_death.mp3` begins when the expanding brown pool appears.
- Automated runtime tests live in `tests/` (excluded from the Web export):
  `sor2_moves_test.tscn` (43 checks covering every move, grab, throw, special,
  weapon, pickup, flanking and the timer), `campaign_smoke_test.tscn` (injects
  the autoplay bot into MainFlow for a full four-stage run) and
  `visual_capture.tscn` (windowed screenshots). See §9 for commands.
- `scripts/testing/balance_autoplay_bot.gd` is a test-only runtime-injected campaign
  driver; no shipping scene references it. It walks the full route, fights through
  normal hitboxes/AI, accepts continues and records stage HP/lives/score so balance
  changes can be compared repeatably.
- The public Web preview is deployed by `.github/workflows/pages.yml` to
  https://claypricepeter-source.github.io/projectbeatemup/ using Godot 4.7's
  single-threaded Web export. `MobileControls` is runtime-drawn and asset-free,
  remains hidden during desktop play, and feeds the canonical InputMap actions.
- This editor session can retain stale editor-side "EventBus not found" rows after
  external script scans (autoload compilation order); fresh `project_run` calls and
  the game logs compile and run clean. Judge changes from `current_run_errors` plus
  the current game log, not retained rows from an older run.
- Git: the writable repository is
  https://github.com/claypricepeter-source/projectbeatemup; the original upstream
  remains https://github.com/ariesyous/projectbeatemup. Its `main` branch began as
  one squashed root snapshot; prior local history is retained only on
  `codex/pre-squash-history`.

---

## 1. Game Overview

| | |
|---|---|
| **Title** | Project Beatemup (working title) |
| **Genre** | 2D side-scrolling beat-em-up (brawler) |
| **Platform** | PC (Windows) + Web preview, keyboard + gamepad |
| **Engine** | Godot 4.7 (GDScript, typed) |
| **Art style** | 16-bit SNES-era pixel art, sourced from free asset packs |
| **Influences** | Streets of Rage 1 & 2, Final Fight |
| **Players** | Single-player (architecture is co-op-ready; local co-op is a stretch goal) |
| **Length** | 4 stages, ~40–50 minutes for a full run |
| **Tone** | Gritty-but-lighthearted small-town Canada. Serious brawling, wry local flavour. |

**Elevator pitch:** A crime syndicate is muscling into sleepy Owen Sound, Ontario.
Sean — a bald, no-nonsense local in his mid-30s — walks out his front door, cracks his
knuckles, and punches his hometown clean, from downtown 2nd Avenue to the Mill Dam.

---

## 2. Story & Setting

### Premise
The **Bayshore Syndicate**, a smuggling outfit using Georgian Bay shipping lanes, has
moved into Owen Sound. Overnight the quiet streets fill with hired punks, shakedowns
hit the downtown shops, and the harbour becomes a front for contraband. The police
are outmatched and compromised. Sean, who grew up here and knows every alley, decides
enough is enough.

Story is told through short text intro cards before each stage (SoR1-style) — no
cutscene animation required.

### Setting: Owen Sound, Ontario, Canada
Real-location flavour to weave into backgrounds and stage names:
- **Downtown 2nd Avenue East** — historic storefronts, brick facades, streetlights.
- **The harbour / Georgian Bay waterfront** — docks, moored boats, shipping containers, the iconic grain elevators.
- **Harrison Park** — trees, the Sydenham River, footbridges, picnic areas.
- **The Mill Dam** — fish ladder, rushing water; dramatic final-showdown scenery.
- Ambient details: Canadian flags, hockey references, a Tim-Hortons-like coffee shop ("Timbo's"), snow-free late-autumn look.

### Story beats
1. **Intro card:** Sean watches a shakedown outside his favourite coffee shop. He steps in.
2. **After Stage 1:** A beaten punk coughs up that shipments come through the harbour.
3. **After Stage 2:** Ragnaros reveals the Syndicate's candy-factory front.
4. **After Stage 3:** Jawbreaker reveals Victor escaped upward in the cargo elevator.
5. **Ending:** Sean defeats Victor at the penthouse. The town wakes up quiet again. Sean gets his coffee.

---

## 3. Characters

### 3.1 Sean (player character)

| | |
|---|---|
| **Appearance** | Bald, caucasian, mid-30s, athletic build. Practical clothes: plain t-shirt (dark teal), jeans, work boots. |
| **Fighting style** | Scrappy brawler — boxing-derived punches, hard low kicks. No flash, all function. |
| **Personality** | Calm, dry, protective of his town. |

**Stats (baseline — tune in `resources/`):**
- Max HP: 104 (the SoR2 life bar; coffee restores 32, specials cost 8)
- Walk speed: 120 px/s (X), 80 px/s (Y-depth)
- Jump: ~0.66 s airtime, arc fixed at takeoff
- Full SoR2 move set and damage table: §4.2

**Required animations** (names are canonical — use these exact animation names in `SpriteFrames`):
`idle`, `walk`, `attack_1`, `attack_2`, `attack_3`, `jump`, `jump_kick`, `hurt`,
`knockdown`, `getup`, `death`, `victory`. The SoR2 states additionally use the
Clay set's `light_punch`, `strong_punch`, `light_kick`, `strong_kick`,
`flying_knee`, `run`, `power_forearm`, `burning_uppercut`, `spinning_backfist`,
`crouch_block` and `throw` (timed to each move with `Fighter.play_timed`).

### 3.2 Enemy roster (4 base types + palette swaps)

All enemies share the animation set: `idle`, `walk`, `attack`, `hurt`, `knockdown`, `death`
(Biker adds `charge`).

| Enemy | Role | HP | Damage | Behaviour |
|---|---|---|---|---|
| **Punk** | Basic melee fodder | 25 | 5 | Approaches directly, single swing, brief retreat after attacking. First enemy built; AI template for the rest. |
| **Thug** | Heavy / tank | 60 | 12 | Slow approach, big telegraphed haymaker with long windup. Doesn't flinch from the first hit of a combo (armor on hit 1). |
| **Knife Punk** | Spacing threat | 20 | 8 | Keeps mid-distance, lunges with a knife stab. Fragile — dies fast once cornered. |
| **Biker** | Charger | 35 | 10 | Circles at range, then telegraphs and charges horizontally across the screen. Vulnerable after a missed charge. |

**Palette swaps** (same sprites, recoloured, stat multipliers): e.g. *Punk → Red Punk*
(1.5× HP, Stage 2+), *Thug → Dock Thug* (Stage 2+), *Knife Punk → Park Punk* (Stage 3).
Palette swaps are a data change (a `Resource` with a modulate/palette + stat multipliers),
not new scenes.

### 3.3 Bosses (one per stage)

| Boss | Stage | Gimmick |
|---|---|---|
| **"Slick" Rick Delaney** — corrupt downtown fixer in flamboyant magnetic armour | 1 — Downtown | Fast dashes and metal-swipe flurries; periodically calls in 2 Punks. Teaches: prioritize adds vs. boss. |
| **Ragnaros** — flamboyant firelord wielding a claymore-sized flaming common stinkhorn | 2 — Sewers | Long horizontal reach and a full-lane sweep; periodically braces the stinkhorn like a gun and fires five white liquid shots. Dodging three shots forces a 3.2 s dizzy punish window. Teaches: use the depth axis. |
| **Jawbreaker** — pink candy-factory guardian | 3 — Candy Factory | Magnetic-armour dash/flurry boss with anti-stunlock counter and candy palette. |
| **Victor Bayshore** — syndicate leader | 4 — Penthouse Elevator | Two phases: (1) brawler with combo strings; (2) at 50% HP, enrages — faster, adds a charging grab. |

Boss HP baseline: 200 / 250 / 300 / 350. Bosses cannot be stun-locked: after 3 consecutive
hits taken, boss gains brief hyper-armor and counterattacks.

---

## 4. Gameplay Design

### 4.1 Core loop
Walk right → invisible trigger locks the camera and spawns an enemy wave →
defeat everyone in the wave → "GO →" indicator flashes → camera unlocks →
repeat → boss arena → boss fight → stage clear score tally → next stage.

### 4.2 Combat spec — Streets of Rage 2 (Axel's values, SoR2 move FAQ)

Buttons map to the SoR2 pad: **A = SPECIAL** (`special_p1`), **B = ATTACK**
(`attack_p1`), **C = JUMP** (`jump_p1`). All damage is out of a 104 HP bar.

**Ground (`player_attack.gd`, `player_double_kick.gd`, `player_blitz.gd`, `player_back_attack.gd`):**

| Move | Input | Damage |
|---|---|---|
| Combo | B repeatedly | jab 6 → jab 6 → straight 8 → low sidekick 10 → high sidekick 14 KD |
| Double sidekick | hold B ≥0.4 s, release | 16 + 20 KD |
| Blitz (Grand Upper) | →, →, B (taps within 0.3 s, B within 0.45 s) | 24 + 4 + 20 KD, dashes forward |
| Back attack | hold B, press C | elbow 8 + backfist 12 KD, behind; armed = throw weapon (8) |

- The combo only advances on a connected hit; a whiff restarts at the jab
  (memory lasts 0.55 s). The low sidekick knocks down on its own; a press in the
  last 3 frames (0.05 s) of the straight chains both kicks instead (the SoR2
  two-frame trick, slightly widened). The blitz, back attack and specials can
  cancel the combo.

**Specials (`player_special_*.gd`):** SPECIAL alone = defensive spin, fully
invulnerable, hits both sides for 16 KD, costs 8 HP **only if it hits**.
Toward + SPECIAL = advancing eight-hit flurry (6+8+8+10+6+8+8+20 KD), not
invulnerable, **always** costs 8 HP. Specials can never KO the player (min 1 HP).

**Air (`player_jump.gd`):** one attack per jump. Straight up + B = knee 10 then
kick 20 KD; diagonal + B = jumping sidekick 8 KD (active until landing);
Down + B = knee press 12, no KD.

**Grapple (`player_grab.gd`, shared `grabbed.gd`/`thrown.gd`):** walking into
an enemy (toward it, or up/down onto it, within 42 px and ±8 px depth) holds it
if it is in Idle/Move/Approach/Recover/Hurt/Taunt/Dizzy and not armored. From
the front: toward+B knee 8, knee 8, double knee 8+10 KD; B headbutt 22 KD;
away+B back throw 24 KD; C vault to its back (a second vault lets go). From
behind: B body slam 28 KD. Thrown bodies hit their own team for 16 KD; the
victim's damage lands on impact. The player is invulnerable during throws,
vaults and pickups; grabbing drops any held weapon. Idle holds are broken after
`grab_escape_time` (1.6 s enemies, 0.8 s bosses; each knee extends it). A
thrown player holding Up + C lands on their feet (SoR2 "Land"). `Grabbed` and
`Thrown` are installed on every fighter at runtime by `Fighter._ready`.

**Weapons (`scripts/combat/weapons.gd`, `weapon_pickup.gd`, `thrown_weapon.gd`):**
knife 16 (no KD), pipe 24 KD, drawn procedurally (no weapon art). Picked up
with B. Dropped when grabbing, being knocked down/thrown, or picking up another
weapon; each weapon vanishes after its third drop. Knife Punk (and Park Punk)
carry knives and Dock Thugs carry pipes (`EnemyStats.weapon`); they drop them
when knocked off their feet.

**Hit rules:**
- Attacks connect only on X overlap **and** within a ±12 px Y-depth band
  (Hitbox `depth_band`); jump attacks use ground depth.
- Hitboxes re-scan overlaps every active physics frame, so back-to-back hit
  windows always register. `Hitbox.Reach.BOTH` covers both sides.
- Hitstun: 0.4 s for enemies (long enough to chain the full string), 0.3 s for
  the player. Knockdowns pop, bounce once, lie 0.7 s and get up invulnerable;
  the player gets ~1 s of i-frames after rising.
- Anti-stunlock (3rd hit within 0.7 s → KD) applies to the player only.
  Thug ignores flinches while his haymaker is committed. Bosses counter on the
  4th hit within 1.0 s and cannot be grabbed while armored.
- Hit-pause, flashes and shake: unchanged (§8 Phase 6). The old sticky
  depth-snap on player hits was removed (SoR2 has no such snap).

**Enemy AI:** shared FSM as before plus SoR2 habits in `enemy_approach.gd`:
enemies flank to the player's free side (`Enemy.preferred_side`) and hesitate
0.12–0.45 s in range before swinging. Max two attackers at once (courtesy rule).

**Pickups:** pressed with B, never auto-collected. Coffee = SoR2 apple (+32),
poutine = chicken (full heal), cash stack 1,000, loonie stack 5,000.

**Timer, lives and scoring (`round_timer.gd`, `game_state.gd`, `main.gd`):**
the HUD timer counts down from 99 (one count per 1.5 s) and refills on each wave
clear and respawn; 0 = TIME OVER, costing a life. Every connected hit scores
damage × 10, throws score their damage × 10, kills keep their resource points.
Extra life every 50,000 points. Stage clear tally = time left × 100 + HP × 10.
3 lives per credit, 3 continues. High-score saves are throttled to one write
per 5 s during play (and always on clear, game over and title).

**HUD (`hud.gd`, drawn in code):** SoR2 layout — portrait (cropped from the
fighter's own idle frame), score, name, `=lives` and a yellow bar with a red
drain ghost; below it the last-hit enemy (or the boss) with portrait, name and a
bar in 104 HP layers (extra layers stack colours and show `xN`). Big timer top
centre, flashing GO arrow, TIME OVER / 1 UP banners.

**Enemy stats (104 HP scale):** Punk 48/8, Knife Punk 40/12, Biker 64/12,
Thug 96/16, Slick Rick 320, Ragnaros 400, Jawbreaker 440, Victor 520 (HP/damage
in `resources/enemies/`; variants keep their multipliers).

### 4.3 Explicitly deferred (stretch)
Local co-op, extra playable characters, difficulty settings, enemies that grab
and throw the player (SoR2 Signal; the thrown/"Land" side is already built),
enemies picking weapons up, grenades/swords/kunai.

---

## 5. Stages

Each stage = one long scrolling scene (~6–8 screens wide), 3–5 combat waves, breakable
props with pickups, then a boss arena.

### Stage 1 — "Second Avenue at Night" (Downtown)
- **Look:** Night. Historic brick storefronts, glowing shop signs (bakery, record store, "Timbo's"), parked cars, streetlights. Parallax: distant rooftops + night sky / near storefronts / street.
- **Enemies:** Punk, Knife Punk. Waves: (2 Punks) → (2 Punks + 1 Knife Punk) → (3 Punks) → (2 Knife Punks + 1 Punk).
- **Boss:** "Slick" Rick Delaney, in front of the smashed-up coffee shop.
- **Music mood:** Driving synth-funk, SoR1 opening-stage energy.
- **Teaches:** basic combat, camera-lock waves, breakables.

### Stage 2 — "The Sewers of Shame" (Industrial sewer beneath the waterfront)
- **Look:** A long grimy processing tunnel with concrete platforms, sewer grates, chains and animated acid channels. Parallax: foreground chains over the repeating tunnel wall.
- **Enemies:** Punk (red swap), Thug, Biker debut. Waves: (2 Punks + 1 Thug) → (2 Bikers) → (1 Thug + 2 Knife Punks) → (2 Thugs) → mini-gauntlet (1 of each).
- **Boss:** Ragnaros, wielding a dark-brown flaming *Phallus impudicus* claymore with a hanging biological ammunition pouch. His five-shot liquid barrage becomes a 3.2 s dizzy opening after three dodges.
- **Music mood:** Tense bass-heavy groove, industrial percussion.
- **Teaches:** depth-axis dodging (Biker charges, Ragnaros's sweeps and aimed liquid shots), armor enemies, earned boss punish windows.

### Stage 3 — "The Nightmarish Candy Factory"
- **Look:** Fluorescent candy-processing machinery, candy-cane pillars and a hot-pink boiling sugar-sludge channel.
- **Enemies:** Five mixed waves using the established roster and Stage 3 variants.
- **Boss:** Jawbreaker, a pink magnetic-armour guardian.
- **Music mood:** Fast, uncanny industrial chiptune.
- **Teaches:** sustained mixed-wave pressure before the confined finale.

### Stage 4 — "The Elevator to the Penthouse" (Finale)
- **Look:** A fixed cargo-elevator platform rising through a scrolling industrial shaft.
- **Enemies:** Four mixed waves drop onto the elevator from overhead.
- **Boss:** Victor Bayshore, two phases, after the elevator reaches the penthouse.
- **Music mood:** Urgent ascent, shifting to the final boss cue.
- **Teaches:** survival and crowd control in a confined arena.

---

## 6. Art Direction & Asset Pipeline

### 6.1 The 16-bit look (technical)
- **Base viewport:** 640×360, integer-scaled to window (project settings:
  `display/window/stretch/mode = viewport`, `stretch/scale_mode = integer`).
- **Textures:** nearest-neighbour filtering project-wide
  (`rendering/textures/canvas_textures/default_texture_filter = Nearest`).
- **Pixel snap:** enable 2D pixel snap (`rendering/2d/snap/snap_2d_transforms_to_pixel = true`).
- **Palette discipline:** favour packs with limited SNES-like palettes; avoid mixing wildly different pixel densities (target ~100×100 px character frames).

### 6.2 Free-asset-pack strategy
Sourced art, adapted to theme. **Rules:**
1. **Verify the license of every pack before importing** (CC0 / CC-BY / "free for commercial use" — read the actual license text on the pack page).
2. Record every pack in **`CREDITS.md`** (pack name, author, URL, license) the moment it's imported.
3. Keep originals in `assets/_source_packs/<pack-name>/` untouched; edited/recoloured copies go into the working folders.

**Candidate sources** (evaluate during Phase 0):
- itch.io free beat-em-up sprites: https://itch.io/game-assets/free/tag-beat-em-up/tag-sprites — includes ~100×100 16-bit-style brawler characters with up to 25 animations each, and the "Streets of Fight" asset pack.
- itch.io free beat-em-up pixel art: https://itch.io/game-assets/free/tag-beat-em-up/tag-pixel-art
- OpenGameArt (https://opengameart.org) — backgrounds, tiles, SFX.
- Kenney (https://kenney.nl) — UI, fonts, SFX (CC0).

**Adaptation notes:**
- **Sean:** pick the closest bald/short-haired male brawler base; recolour clothes to dark teal shirt + jeans. If no bald base exists, a small head-region pixel edit is acceptable.
- **Enemies:** one pack family if possible for style cohesion; palette swaps via Godot `modulate`/shader or pre-recoloured sheets.
- **Backgrounds:** recompose pack tiles/props to *evoke* Owen Sound landmarks (grain elevators = industrial silo assets; Mill Dam = water/industrial assets). Add custom signage text for local flavour.

### 6.3 Asset folders
```
assets/
  _source_packs/     # untouched downloads, one folder per pack
  sprites/           # character SpriteFrames source sheets (player/, enemies/, bosses/)
  backgrounds/       # per-stage parallax layers
  props/             # breakables, pickups
  audio/music/       # per-stage tracks
  audio/sfx/
  fonts/
  ui/
```

---

## 7. Technical Architecture (Godot 4.7)

### 7.1 Project file layout
```
AGENTS.md              # this file — source of truth
CREDITS.md             # asset attribution (created Phase 0)
project.godot
scenes/
  main.tscn            # root: handles stage flow, screens
  ui/                  #   title_screen.tscn, hud.tscn, game_over.tscn, pause_menu.tscn
  stages/              #   stage_1.tscn, stage_2.tscn, stage_3.tscn
  characters/          #   player.tscn, enemies/punk.tscn, ... bosses/...
  props/               #   breakable.tscn, pickup.tscn
scripts/
  autoload/            #   game_state.gd, event_bus.gd, audio_manager.gd
  characters/          #   fighter.gd (base), player.gd, enemy.gd, states/*.gd
  stages/              #   stage.gd, wave_trigger.gd, camera_director.gd
  ui/
resources/
  enemies/             #   punk.tres, thug.tres ... (EnemyStats custom Resource)
  waves/               #   per-stage wave layouts (WaveData Resource)
```

### 7.2 Scene structure (per stage)
```
Stage (Node2D, script stage.gd)
├── ParallaxBackground (2–3 ParallaxLayers)
├── Ground (visual street/floor layer)
├── Entities (Node2D, y_sort_enabled = true)   # player, enemies, props all live here
├── WaveTriggers (Area2D children along X)
├── Camera2D (script camera_director.gd — follow + lock zones + stage X limits)
└── BossArena (marker + boss spawn)
```

### 7.3 The beat-em-up ground plane (core trick)
- Characters move freely in X (along the street) and Y (depth into the scene) on a
  walkable band (e.g. `walk_min_y` to `walk_max_y` exported per stage).
- **Draw order** = Y-sort on `Entities` (lower on screen renders in front).
- **Jumping** is visual: the character keeps a logical `ground_y` (depth) while a
  child sprite offsets upward by `jump_height`; a blob shadow stays at `ground_y`.
  Hit detection during a jump uses `ground_y`, not the sprite position.
- **Hits connect** only when hitbox/hurtbox overlap in X **and**
  `abs(attacker.ground_y - target.ground_y) <= 12`.

### 7.4 Characters: shared `Fighter` base + FSM
- `fighter.gd` (extends `CharacterBody2D`): HP, facing, ground_y, jump offset,
  hurt/knockdown handling, `take_hit(damage, knockdown, source)`; emits `died`, `hit_taken`.
- `player.gd` and `enemy.gd` extend it. Enemy behaviour + stats come from an
  `EnemyStats` custom `Resource` (HP, speed, damage, points, palette, timings) so new
  enemies/palette swaps are data, not code.
- **FSM:** lightweight state-machine node with one script per state
  (`idle`, `move`, `attack`, `hurt`, `knockdown`, `getup`, `dead`; enemies add
  `approach`, `circle`, `retreat`, `charge`). States own animation choice and transitions.

### 7.5 Hitboxes / hurtboxes / collision layers
`Area2D` children: **Hurtbox** (always on) and **Hitbox** (enabled only during attack
active frames, via `AnimationPlayer` method track or frame callback).

| Layer | Name | Used by |
|---|---|---|
| 1 | world | camera limits, walls |
| 2 | player_hurtbox | Sean's Hurtbox |
| 3 | enemy_hurtbox | enemy Hurtboxes |
| 4 | player_hitbox | Sean's Hitbox (masks 3) |
| 5 | enemy_hitbox | enemy Hitboxes (masks 2) |
| 6 | props | breakables (masked by 4) |
| 7 | pickups | pickup Area2D (masks 2) |

### 7.6 Autoloads
- **`GameState`** — score, high score (persist to `user://save.cfg` via `ConfigFile`), lives, continues, current stage index; `reset_run()`, `next_stage()`.
- **`EventBus`** — global signals: `enemy_died(points)`, `player_died`, `wave_cleared`, `stage_cleared`, `boss_health_changed(ratio)`, `pickup_collected(kind)`.
- **`AudioManager`** — music crossfade per stage, pooled SFX players.

### 7.7 Input map (co-op-ready convention)
All gameplay actions are **suffixed with player index** from day one: `move_left_p1`,
`move_right_p1`, `move_up_p1`, `move_down_p1`, `attack_p1`, `jump_p1`,
`special_p1`, plus global `pause`. Player scenes take an exported `player_index: int`; input reads
`"%s_p%d" % [action, player_index]`. Adding P2 later = new bindings + spawn, no rework.

Default bindings: Arrows/WASD + `Z`/`J` attack + `X`/`K` jump + `C`/`L` special;
gamepad D-pad/stick + face buttons (special = Y/Triangle). Camera and HUD are written against "list of players" (length 1 for now).

### 7.8 Camera & waves
- `camera_director.gd`: follows average player X (co-op-ready), clamped to stage
  limits; `lock(x_center)` / `unlock()` API.
- `wave_trigger.gd` (`Area2D`): on player enter → locks camera, spawns its
  `WaveData` (enemy scene + stats resource + spawn edge/offset list), listens for all
  deaths → emits `wave_cleared` → unlock + "GO →" HUD indicator.

---

## 8. Phased Roadmap

> Work top to bottom. Each phase ends with a **Definition of Done (DoD)** — verify it
> by *running the game* before checking the box and moving on. Check boxes off in this
> file as items complete.

### Phase 0 — Project setup & asset selection
- [x] Configure project settings: 640×360 viewport, integer scaling, nearest filtering, pixel snap.
- [x] Create folder structure from §7.1 and `.gitignore`d `git init` (repo not yet initialized).
- [x] Create input map actions from §7.7 (keyboard + gamepad bindings).
- [x] Choose packs: **Streets of Fight (free) by ansimuz** selected as primary (characters + enemies + street art; free commercial use). ⚠ Download pending — user must download from itch.io into `assets/_source_packs/streets-of-fight/`. **Sprites render at 2× scale** (pack targets 240px stages, ~47px characters) — see CREDITS.md notes.
- [x] Create `CREDITS.md` with attributions.
- [x] **DoD:** `main.tscn` runs at 640×360 with crisp integer scaling (verified via MCP run + screenshot). Remaining: asset zip download (manual).

### Phase 1 — Core movement
- [x] `fighter.gd` base + FSM skeleton (`idle`, `move`, `jump` states; `scripts/characters/`).
- [x] `player.tscn`: Sean with `AnimatedSprite2D` (all 9 pack animations in `assets/sprites/player/sean_frames.tres`, canonical names), 8-direction ground-plane movement with X+Y clamping, sprite flip on facing.
- [x] Jump: visual sprite offset + blob shadow, node stays on ground plane (§7.3).
- [x] Test scene `scenes/stages/test_street.tscn` (patched pack preview art, 2360×480 world); Y-sort proven with barrel prop.
- [x] `camera_director.gd` follow + limits.
- [x] **DoD:** verified in-game via MCP (walk 120px/s, camera scroll, jump air-sim, Y-sort behind/in-front, bounds clamping).

> **Phase 1 notes:** Sean now uses the user-provided `clay_character_godot` sprite
> set: a bald male fighter matching the intended silhouette. Its 256×192 frames render
> at native 1× with the supplied (128, 176) feet anchor. `player.gd` installs canonical
> runtime aliases so the existing FSM uses light punch, strong punch, strong kick,
> flying knee, get-hit and dedicated knocked-down frames without changing combat logic.
> A reference-driven generated refinement now supplies Sean's active ten-frame idle
> and ten-frame ground combo while retaining his bald head, glasses, black tank top,
> gloves and green camouflage trousers. The combo's three contact frames still deal
> the canonical 6+6+12 damage and require buffered attack presses to unlock all hits.
> The previous Streets of Fight Brawler Girl resource remains in the project but is no
> longer assigned to `player.tscn`; confirm the Clay folder's redistribution permission
> before the next public export (see CREDITS.md).
> `assets/props/barrel.png` holds two barrel variants — use `region_rect = Rect2(0, 0, 28, 48)`
> for the upright one. Implementation detail: jump is a state; airborne attack (jump_kick)
> hooks into `player_jump.gd` in Phase 2.

### Phase 2 — Combat core
- [x] Hitbox/hurtbox scenes + collision layers (§7.5); hitbox windows driven by animation frames (`scripts/combat/`).
- [x] Player 3-hit combo + jump kick (§4.2 timings/damages) — `player_attack.gd`, jump kick in `player_jump.gd`.
- [x] `hurt`, `knockdown`, `getup`, `death` shared states (getup folded into `knockdown.gd`'s phase timeline); hitstun & i-frame rules.
- [x] `EnemyStats` resource; **Punk** enemy with full AI FSM (Idle/Approach/Attack/Recover) and the max-2-attackers rule.
- [x] Player + enemy health bars (`scenes/ui/hud.tscn`); enemy death → `EventBus.enemy_died`.
- [x] **DoD:** verified in-game via MCP — combo dealt exactly 6+6+12 with finisher knockdown; jump kick 10 + knockdown; kill emits points and frees the enemy; player death reloads the scene (Phase 4 replaces with lives/continues).

> **Phase 2 notes:**
> - **Anti-stunlock rule (now canonical, §4.2 addendum):** a 3rd consecutive hit
>   within 0.7s is upgraded to a knockdown. Without it, two synced enemies
>   permanently hitstun-lock the victim (observed in testing).
> - Standard Punk and its Red Punk data variant use the generated Sikh Punk atlas:
>   sixteen transparent 160×128 frames across `idle`, `walk`, `attack`, and `hurt`,
>   authored facing right at native 1×. Runtime verification loaded all four
>   animations and screenshot-checked its scale beside Sean. Other enemy scenes
>   keep their prior art resources.
> - The free pack has no knockdown/getup/death frames — knockdown/death reuse
>   `hurt` with a 90° sprite rotation while lying. Revisit if better frames land.
> - `EventBus` signal params must stay **untyped** (circular dependency with
>   Fighter breaks editor-side compilation).
> - Editor session may show stale "EventBus not found" compile errors until the
>   editor restarts (autoload added mid-session); the game compiles clean.
> - Known polish TODO: enemies can stack on the same spot (no soft separation);
>   scheduled for Phase 3 alongside wave AI tuning.

### Phase 3 — Stage 1 vertical slice
- [x] `stage_1.tscn`: full downtown scene, 3 parallax layers, ~6–8 screens wide.
- [x] `wave_trigger.gd` + `WaveData`; author Stage 1 waves (§5).
- [x] Camera lock/unlock + "GO →" indicator.
- [x] **Knife Punk** enemy; breakable props + Coffee/Cash pickups.
- [x] **Boss 1 (Slick Rick)**: dash/flurry AI + add-summoning; boss HP bar.
- [x] Win flow (stage-clear tally) and lose flow (lives → continue → game over), minimal screens.
- [x] **DoD:** Stage 1 playable start-to-finish from `main.tscn`; losing and winning both route correctly.

> **Phase 3 notes (complete):**
> - `stage_1.tscn` is a 4480×480 (7-screen) downtown composition built directly
>   from `Stage Layers/tileset.png` atlas regions at 2× scale. Three parallax
>   layers supply night sky, skyline, and near rooftops; the walkable band remains
>   y ∈ [204, 264] and the boss arena is staged outside Timbo's at the east end.
> - `main.tscn` now owns the Phase 3 run flow: three lives, in-place full-HP
>   respawns with 2 s of i-frames, a 10-second continue prompt (three continues),
>   Game Over/retry, and a stage-clear tally with the remaining-HP × 10 bonus.
> - Four `WaveData` resources encode the exact §5 lineups. `WaveTrigger` owns
>   spawn/death accounting; verified Wave 1→4 as 2 Punk, 2 Punk + Knife Punk,
>   3 Punk, and 2 Knife Punk + Punk. Camera locks also temporarily constrain the
>   player's X bounds. Enemies now use soft separation (coincident enemies moved
>   58 px apart in the runtime probe) and per-scene source-facing metadata so the
>   sprite and attack hitbox both point toward Sean from either side.
> - Wave clear atomically unlocks the camera, restores full stage movement bounds,
>   and pulses a gold `GO →` cue before auto-hiding; verified on-screen and with a
>   clean runtime log.
> - Knife Punk is a 20 HP / 8 damage / 150 point mid-range enemy with a dedicated
>   approach and 190 px/s lunge state (verified 44 px travel and exactly 8 damage).
>   Trash cans and crates take normal player-hitbox damage and drop Coffee (+25 HP),
>   Cash (+500), or loonie stacks (+100); pickups update HP/score and HUD feedback.
>   `GameState` now owns run score and receives untyped `EventBus.enemy_died` events.
> - Slick Rick now uses the user-provided `magneto_boss_codex_assets` art at native
>   1× scale, with its manifest's 384×224 canvas, (192, 212) feet pivot, authored
>   frame order/FPS, nearest filtering, and dedicated KO art. His 200 HP FSM retains
>   its 143 px dash (12 + KD), 6+6+10 swipe flurry, punishable recovery, and armored Counter on the third
>   quick hit. He periodically maintains two Punk adds (verified 2→1→2), with all
>   special states respecting the max-two-attacker rule. The boss bar tracks exact
>   health ratio and hides on death; boss defeat cleans up adds and emits stage clear.
>   Rainbow Meteor and the throw victim are correctly authored as separate visual
>   layers and exposed as QA/future-state hooks; they are not active combat moves in
>   v1 because grabs/throws and extra player specials remain explicitly deferred.
> - Final DoD run crossed all four physical wave triggers in one launch, verified
>   all 11 enemies and exact lineups, then spawned Slick Rick plus two adds. Wave
>   score was 1250; boss/add cleanup plus an 87-HP clear bonus produced the exact
>   4320 tally and `STAGE_CLEAR` route. The lose-flow run separately verified one-life
>   respawn, continue acceptance (3 lives / 1 continue consumed), and zero-credit
>   Game Over. Both runs had empty current-run error logs and were screenshot-checked.

### Phase 4 — Game loop & UI
- [x] Title screen (start / quit), stage intro text cards (§2 story beats), pause menu.
- [x] Full HUD: player HP, lives, score, boss bar, GO indicator, pickup feedback.
- [x] Continues + Game Over screen; high score persisted via `GameState`.
- [x] Stage transition flow in `main.tscn` (`GameState.next_stage()`).
- [x] **DoD:** full loop title → intro card → Stage 1 → clear/game-over → title; high score survives restart.

> **Phase 4 notes (complete):**
> - `main.tscn` now starts at a keyboard/gamepad/mouse title menu, shows the Stage 1
>   story card before instantiation, and owns dedicated pause and Game Over scenes.
>   The stage is disabled while overlays are active, so menu input remains live
>   without enemies or timers progressing behind it.
> - `MainFlow.STAGE_SCENES` and matching intro-card data form the campaign shell.
>   Clear calls `GameState.next_stage()`; Stage 2 was added in Phase 5 and the same
>   shell is ready for Stage 3.
> - `GameState` loads/saves `high_score` in `user://save.cfg` via `ConfigFile` and
>   writes whenever a new high score is reached. The full Phase 3 HUD already covered
>   player HP, lives/continues, score, boss HP, GO, enemy HP, and pickup feedback and
>   was retained unchanged under the new shell.
> - Runtime verification used actual Z/Esc input for title→intro→stage and pause→resume,
>   probed continue acceptance (3 lives restored and one credit consumed), checked
>   Game Over/clear routing back to title, and restarted the project to confirm the
>   exact saved high score was reloaded. All tested screens were screenshot-checked.

### Phase 5 — Stages 2–4
- [x] **Thug** and **Biker** enemies (armor + charge behaviours); palette-swap resources.
- [x] `stage_2.tscn` sewer: art, waves, **Boss 2 (Ragnaros)** with stinkhorn sweep and dodge-to-dizzy liquid barrage.
- [x] `stage_3.tscn` candy factory: repeating art, sugar-sludge effects, five waves and **Boss 3 (Jawbreaker)**.
- [x] `stage_4.tscn` elevator finale: scrolling shaft, four drop-in waves and **Boss 4 (Victor Bayshore)**.
- [x] Poutine pickup; anti-stunlock boss armor rule (§3.3).
- [x] **DoD:** original 3-stage campaign playable start-to-finish.
- [x] **Four-stage extension DoD:** run Candy Factory → Elevator → Victor → ending without runtime errors.
  **Verified 2026-09-24 by `tests/campaign_smoke_test.tscn`: the autoplay bot
  cleared all four stages through the ending in 2 of 3 SoR2-build runs (the
  third ran out of continues in Stage 2), with no script errors in the final runs.**

> **Phase 5 progress notes:**
> - Thug is a 60 HP / 12 damage / 300 point heavy with a held haymaker telegraph.
>   His first ordinary combo hit deals damage without interrupting his action; the
>   second flinches and the third quick hit forces knockdown as usual.
> - Biker is a 35 HP / 10 damage / 200 point spacing enemy with the canonical
>   `charge` animation/state. He circles at range, telegraphs, commits to a fast
>   lane-locked horizontal charge, and has a 1.15 s punish window after a miss.
>   Charge counts toward the global max-two-attackers courtesy rule.
> - `red_punk.tres`, `dock_thug.tres`, and `park_punk.tres` inherit base enemy stats
>   through resource multipliers. `WaveData`/`WaveTrigger` accept optional per-spawn
>   stat overrides so palette variants stay data-only.
> - `roster_test.tscn` exercises Sean, Thug, Biker, and Red Punk together. Runtime
>   probes verified Thug's armor/flinch/knockdown sequence, a 254 px missed Biker
>   charge with the long recovery, resolved variant stats, and valid mixed-wave data.
> - `stage_2.tscn` is a 5120×480 industrial sewer processing floor assembled from
>   the user-provided `196124.png` sheet. A native-resolution doorless core repeats
>   into one tunnel; all 15 supplied green rectangular frames animate across both
>   the rear channel and the full lower trench, while the foreground chains scroll
>   18% faster than the camera. Each active acid frame is intentionally stretched
>   vertically across its full channel, matching the requested earlier treatment.
>   A fixed random seed distributes smaller decals only across plain wall slots
>   between the grates, and cleaned curry packages of varied size float 50%
>   submerged at seeded random X and Y positions throughout the lower pool. Runtime
>   verification found twelve packages spanning the full level, with distinct
>   surface depths from y=287.5 to y=344.1. Five
>   `WaveData` resources encode
>   the exact §5 lineups, including Red Punk and Dock Thug stat overrides; runtime
>   verification observed 3/2/3/2/4 enemies with the expected types and values.
> - Ragnaros is a 250 HP / 14 damage / 2500 point boss with a 148 px flaming
>   dark-brown *Phallus impudicus* stinkhorn strike and a clearly marked full-lane
>   stinkhorn sweep. The sweep deals 18 + knockdown in an
>   18 px depth band: a same-lane probe lost exactly 18 HP while a 42 px Y dodge took
>   zero. The weapon base carries a large, soft-lobed, dark-brown fleshy ammunition
>   reservoir based on the supplied creature reference. It is broadly fused directly
>   to the weapon underside near its grip rather than suspended by a cord or stem.
>   Every 8.5 seconds Ragnaros can
>   brace the weapon like a gun and fire five milky-white aimed projectiles. Each shot
>   deals 8 damage in the canonical ±12 px depth band; three misses end the barrage
>   early and create a 3.2-second star-marked Dizzy window. Ragnaros is invulnerable
>   during the barrage, vulnerable throughout Dizzy, and accepts the complete 6+6+12
>   player combo without leaving that punish state. Runtime probes verified one shot
>   dealt exactly 8 damage, three alternating-lane dodges preserved Sean at 100 HP,
>   cleared all remaining shots and entered Dizzy, and the 24-damage combo remained
>   accepted before cleanly returning to Recover. His third quick hit outside Dizzy
>   routes Hurt → Hurt → armored Counter; the HUD now reads
>   boss names from `EnemyStats`, so Slick Rick and Ragnaros label correctly. The
>   internal `marta.tscn`/`marta.gd` identifiers remain for compatibility, but the
>   boss now uses forty generated 256×192 firelord/mushroom frames at native 1×:
>   eight frames each for idle, walk, attack, hurt and the new periodic taunt. A
>   project-native pixel ember layer continuously orbits the lower cyclone, while
>   stepped between-frame flame warps make the seated vortex visibly swirl. Runtime
>   verification loaded all five eight-frame animations, observed the automatic taunt,
>   proved the vortex timer advances continuously, and screenshot-checked idle and
>   the dark-brown flaming stinkhorn attack silhouette, observed attack frame 2 with the hitbox
>   active, and confirmed the strike dealt exactly 14 damage.
> - The campaign shell includes the Stage 2 story card and scene. Verification
>   loaded it through `MainFlow`, defeated Ragnaros to reach `STAGE 2 CLEAR` with the
>   exact HP×10 bonus, and advanced into the Stage 3 card. Boss defeat awarded 2500
>   points, hid the boss bar, and retained the arena camera lock during the tally.
> - `stage_3.tscn` now keeps the existing 5120×480 five-wave structure but renders
>   it as the Nightmarish Candy Factory through `candy_factory_stage.gd`: a repeated
>   factory backdrop, candy-cane pillars and animated hot-pink boiling sugar sludge.
>   Its boss gate spawns the 300 HP / 3000 point Jawbreaker, which inherits the
>   complete Slick Rick boss contract so the shared dash/flurry/counter states remain
>   type-safe while its resource and sprite tint create the candy variant.
> - `stage_4.tscn` is a fixed 640×360 elevator arena. Four `WaveData` resources drive
>   3/3/3/4 enemy lineups that enter through the shared knockdown state and then have
>   their air height/velocity overridden to fall from above. The scrolling shaft stops
>   after the fourth wave and Victor crashes onto the platform.
> - Victor Bayshore remains a 350 HP / 4000 point final boss. Phase 1 uses an 8+8+12
>   three-hit string; crossing 50% HP enters an invulnerable enrage, boosts movement
>   by 30%, changes the string to 10+10+14, and enables a 410 px/s charging grab for
>   18 + knockdown. A missed charge leaves a verified 1.0 s punish window. Three
>   quick incoming hits force an armored 12 + knockdown Counter, and the armor clears
>   after recovery. Victor reuses the licensed boss sheet with a distinct data tint
>   and aura; no additional art license was introduced.
> - The rare poutine drops from the pre-boss crate and fully heals. Runtime validation
>   broke the configured crate, observed one `poutine` pickup, healed Sean from 7 to
>   100, and displayed `POUTINE  FULL HEAL` on the HUD.
> - The earlier three-stage finale verification defeated Victor through the normal Death state, awarded 4000
>   points plus an exact 73 HP × 10 bonus for a 4730 total, showed `STAGE 3 CLEAR`,
>   advanced to the `QUIET WATER` ending, removed the stage, and returned to title
>   with an actual Z press. That verification predates the Candy Factory/Elevator
>   split; the four-stage extension DoD above remains the required final playtest.

### Phase 6 — Audio & polish
- [x] Music per stage + title + boss stinger (free packs, credited); `AudioManager` crossfades.
  **The persistent two-player `AudioManager` crossfades every flow cue. Stages 1–2 use
  supplied MP3s; title, Stage 3, boss, clear, Game Over and ending each use a
  distinct loopable 11.025 kHz project-native chiptune composition generated from
  authored melody/bass/drum profiles. Runtime verification cycled all eight cues,
  confirmed their identities and unique lengths, sought across a generated loop
  boundary without playback stopping, and activated the Stage 1 boss gate to prove
  that `boss_stinger` and the boss cue fire together. Current-run errors and the
  current game log were clean.**
- [x] SFX: hits, whiffs, knockdown, breakables, pickups, UI.
  **Confirmed hits retain the supplied `punch1` / `punch2` alternation and `punch3`
  for defeating blows. `AudioManager` now generates seven license-free 16-bit mono
  cues at runtime and serves them from an eight-player pool. Verification proved a
  missed ground swing emitted `whiff` while a 6-damage confirmed swing played the
  recorded punch without a whiff; breaking a prop, collecting its Coffee, triggering
  knockdown, pressing Z through the intro, and pausing with Esc emitted `breakable`,
  `pickup`, `knockdown`, `ui_confirm`, and `ui_pause` respectively. The supplied
  `deathsean.mp3` now plays once as Sean enters the life-loss Death state; a runtime
  probe identified the routed cue as `player_death`. Supplied `after_death.mp3`
  starts on landing as the pool begins spreading, routed as `after_death`.**
- [x] Game feel: hit-pause (2–3 frames), light screen shake on knockdowns, sprite flash on hit, i-frame flicker.
  **`ImpactManager` now applies an unscaled 0.04/0.055 s connected-hit pause and
  extends overlapping pauses safely. Normal-hit verification dealt exactly 6 damage,
  flashed the victim to 2.2× white, and restored time scale/colour to normal.
  Knockdowns additionally produced a 4 px camera offset that settled back to zero;
  the existing post-getup i-frame flicker remains active. Sean's life-loss KO holds
  the game at 28% speed for 0.9 real-time seconds, then safely restores normal speed
  without conflicting with the connected-hit pause. Runtime verification observed
  the exact 0.28 → 0.08 impact pause → 0.28 KO → 1.0 restoration sequence. After
  landing, Sean remains down for 5.0 seconds while a doubled-size SNES-style stepped
  brown pool expands beneath the body. Six block-pixel bubbles repeatedly swell and
  burst during and after the slower spread; the body then fades for 0.35 seconds
  before the life-loss flow resumes. Runtime verification observed the pool at exactly
  50% expansion after 2.5 seconds with active bubbles and the body still visible, then
  confirmed the completed pool remained animated and
  respawn hid/reset the pool and restored Idle at 100 HP.**
- [x] Balance pass: play full campaign, tune HP/damage/wave sizes in resources.
  **The complete player/enemy/boss/pickup/wave resource audit found the authored
  values internally consistent, so they were retained instead of changed without
  evidence. A repeatable normal-combat autoplay run cleared all three stages with
  five deaths and one continue used: Stage 1 ended at 85 HP / 2 lives, Stage 2 at
  100 HP / 3 lives after the continue, and Stage 3 at 42 HP / 1 life. It finished
  at 19,920 points with a clean current game log, demonstrating rising pressure and
  a beatable finale even for a simple approach-and-mash strategy.**
- [x] **DoD:** full run feels punchy; no silent actions; campaign beatable but challenging (~2–4 continues for an average player).

### Phase 7 — Release
- [ ] Windows export preset (embedded PCK), icon, project name/version.
- [x] Web export preset + GitHub Pages deployment (completed early after Phase 3;
  CI export and live browser controls verified).
- [x] Responsive mobile controls for the Web build.
  **`MobileControls` provides a multi-touch virtual stick with diagonal movement,
  simultaneous ATTACK/JUMP buttons, pause/resume mapping and a contextual NEXT
  button on non-gameplay cards. It is hidden on non-touch desktops and the title/
  pause menus remain directly tappable. Runtime probes moved Sean 54 px through
  touch input, verified two-axis movement, held movement + attack + jump on three
  distinct fingers, and confirmed clean release of every InputMap action.**
- [ ] Final `CREDITS.md` audit + in-game credits screen.
- [ ] Playtest export build outside the editor; fix export-only issues.
- [ ] **DoD:** distributable zip that runs on a clean Windows machine.

### Phase 8 — Streets of Rage 2 remake (2026-09-24)
- [x] SoR2 ground combo (advance-on-hit, double-kick timing), hold-release double sidekick, blitz, back attack.
- [x] Defensive/offensive specials with SoR2 HP costs; third input action `special_p1` + touch button.
- [x] Grapple: grab by walking in, knees, headbutt, back throw (bodies hit enemies), vault, body slam, Land.
- [x] Weapons: knife/pipe pickups, three-drop lifetime, weapon throw, enemy-carried weapons.
- [x] SoR2 jump attacks (vertical, diagonal, knee press); knockdown bounce; enemy flanking + hesitation.
- [x] 104 HP scale, rescaled enemy/boss stats, press-to-pick-up items, per-hit scoring, 50k extends.
- [x] SoR2 HUD, 99 round timer with TIME OVER, time bonus in the clear tally.
- [x] **DoD:** `tests/sor2_moves_test.tscn` 43/43; full campaign cleared by the autoplay bot;
  windowed screenshots reviewed (HUD, combo, grab, throw, special, weapons).
- [ ] Human playtest of feel/timing in the browser build (not yet done).

### Stretch phases (post-v1, in rough priority order)
- [ ] **S1 — Local co-op:** P2 bindings, second player spawn, camera avg of players, shared lives pool.
- [x] **S2 — Grabs & throws:** done in Phase 8.
- [x] **S3 — Weapons:** knife/pipe done in Phase 8 (hockey stick not added).
- [x] **S4 — Special move:** done in Phase 8 (both SoR2 specials).
- [x] **S5 — Run/dash + dash attack:** SoR2 blitz done in Phase 8 (no free run, as for Axel).
- [ ] **S6 — Second playable character; difficulty settings; arcade score attack mode.**

---

## 9. Working Agreements (for AI tools & humans)

### Tooling
- **Godot editor MCP (`godot-ai`) is available** and preferred for: creating/editing scenes and nodes, setting project settings, input map, running the game (`project_run`), reading logs (`logs_read`), and screenshots for visual verification.
- Plain file edits are fine for `.gd` scripts, `.tres` resources, and docs; after external file edits, let the editor rescan before running.
- **After any gameplay change, actually run the game** (test scene or stage) and verify behaviour — via MCP run + logs/screenshot, or ask the user to play. Don't mark roadmap items done on "it compiles."

### Headless testing (no editor needed)
Godot 4.7-stable's console binary can import and run the tests directly:
```
godot --headless --path . --editor --quit                      # import / parse
godot --headless --path . res://tests/sor2_moves_test.tscn     # exit code = failed checks
godot --headless --fixed-fps 60 --path . res://tests/campaign_smoke_test.tscn
godot --path . res://tests/visual_capture.tscn -- <output_dir> # windowed screenshots
```
Warnings are treated as errors (e.g. Variant inference), so a parse failure on
import usually means a missing type annotation.

### Code style
- **Typed GDScript** everywhere (`var speed: float = 120.0`, typed function signatures).
- `snake_case` for files/functions/variables, `PascalCase` for classes/nodes, `class_name` on reusable classes.
- Signals over direct references across scenes; `EventBus` for cross-system events; exported variables for tunables — but **stats belong in `Resource`s** (§7.4), not hardcoded.
- Keep the canonical animation names (§3.1/§3.2) exactly — code depends on them.

### Process
- **This file is the source of truth.** Update roadmap checkboxes as items complete. Design changes get written here *before or with* the code change.
- Work one phase at a time; don't start a phase until the previous DoD is verified in a running game.
- Every imported asset pack: license verified, original preserved in `assets/_source_packs/`, entry added to `CREDITS.md` — no exceptions.
- Commit per completed roadmap item once the repo is initialized (`git init` is a Phase 0 task).
