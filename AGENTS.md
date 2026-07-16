# Project Beatemup — Game Design Document & Roadmap

> **This file is the source of truth for the project.** Any AI tool or human working on
> this game should read this document first, follow its conventions, and update the
> roadmap checkboxes in Section 8 as work completes. If a design decision changes,
> change it *here* first, then in the code.

---

## 0. HANDOFF STATUS (updated 2026-07-16)

**Where the project stands:** Phases 0–5 are complete and verified in-game (see
checked boxes + per-phase notes in §8). The full three-stage campaign, complete
enemy roster, all three bosses, pickups, stage-clear routing and ending card are
playable. **The next task is the final Phase 6 human feel/continue-target playtest**;
the repeatable automated balance run is complete, after which Phase 7 release work
can begin.

**What runs today:** F5 launches `scenes/main.tscn` at the title screen. Start routes
through story cards into three consecutive stages: **Second Avenue at Night**
(four waves + Slick Rick), **The Harbour** (five waves + Marta), and **Harrison
Park to the Mill Dam** (five waves + Victor). Stages include camera locks, props,
pickups, boss bars and stage-clear tallies; the finale adds a narrow footbridge
fight, Victor's two phases, and the ending card. Losing a life respawns in the
active fight; zero lives routes through Continue and Game Over. High score persists
in `user://save.cfg`.

**Controls:** Arrows/WASD move, Z/J attack (mash = 3-hit combo; finisher knocks
down), X/K jump (attack airborne = jump kick), Esc opens/resumes the pause menu.
Gamepad: D-pad/left stick, X/Square attack, A/Cross jump, Start pause.

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
- Stage 2 is 5120×480 (eight screens), with a y ∈ [204, 280] dock plane. Its dusk
  parallax, grain elevators, water, container yards, boats and cranes are drawn from
  project-native Godot shapes in `harbour_stage.gd`; it introduces no new art license.
- Stage 3 is 5120×480 with a y ∈ [204, 280] plane, split between autumn Harrison
  Park and the floodlit Mill Dam in `finale_stage.gd`. Wave 4 clamps both sides to
  the footbridge y ∈ [232, 250] and restores full depth when cleared.
- Combat rules implemented in `scripts/` match §4.2 **plus** the anti-stunlock rule
  (3rd consecutive hit within 0.7s → knockdown) — see §8 Phase 2 notes for this and
  other gotchas. EventBus parameters must stay untyped; Streets of Fight characters
  rotate the `hurt` frame for knockdown, while the new boss uses dedicated KO art.
  Enemy soft separation and per-sheet source-facing metadata are now
  implemented; keep both when adding the Phase 5 roster.
- Phase 3's reusable pieces are `WaveData`/`WaveTrigger`, `CameraDirector`, the
  breakable/pickup base scenes, and `MainFlow`. Boss-wave camera lock intentionally
  remains active while the clear tally is shown.
- Phase 4's `MainFlow` owns title/intro/pause/continue/clear/game-over/ending routing.
  `STAGE_SCENES` and `INTRO_CARDS` contain all three stages; `GameState.next_stage()`
  advances the shell, while high score is persisted immediately through `ConfigFile`.
- Phase 5 enemy variants resolve from `EnemyStats.base_variant` plus stat
  multipliers. `WaveData.enemy_stats` is an optional per-spawn override array; use
  it to mix Red Punk/Dock Thug/Park Punk resources into waves without new scenes.
- `AudioManager` is a persistent two-player music router plus an eight-player SFX
  pool. Stage 1 uses the supplied MP3; title, Stages 2–3, boss, clear, Game Over and
  ending use distinct project-native chiptune loops synthesized at runtime. A boss
  stinger and seven small gameplay/UI cues are also synthesized at runtime, so they
  introduce no external asset license.
- `scripts/testing/balance_autoplay_bot.gd` is a test-only runtime-injected campaign
  driver; no shipping scene references it. It walks the full route, fights through
  normal hitboxes/AI, accepts continues and records stage HP/lives/score so balance
  changes can be compared repeatably.
- The public Web preview is deployed by `.github/workflows/pages.yml` to
  https://ariesyous.github.io/projectbeatemup/ using Godot 4.7's single-threaded
  Web export. The GitHub Actions deployment and live keyboard play were verified.
  The source repository is private because the imported Streets of Fight pack may
  be used in a game but its raw assets must not be redistributed separately.
- This editor session can retain stale editor-side "EventBus not found" rows after
  external script scans (autoload compilation order); fresh `project_run` calls and
  the game logs compile and run clean. Judge changes from `current_run_errors` plus
  the current game log, not retained rows from an older run.
- Git: the private source repository is https://github.com/ariesyous/projectbeatemup.
  Its `main` branch was published as one squashed root snapshot; the prior local
  history is retained only on `codex/pre-squash-history`.

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
| **Length** | 3 stages, ~30–40 minutes for a full run |
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
3. **After Stage 2:** The dock boss reveals the Syndicate leader is holed up past Harrison Park at the Mill Dam.
4. **Ending:** Sean drops the boss into the fish ladder. The town wakes up quiet again. Sean gets his coffee.

---

## 3. Characters

### 3.1 Sean (player character)

| | |
|---|---|
| **Appearance** | Bald, caucasian, mid-30s, athletic build. Practical clothes: plain t-shirt (dark teal), jeans, work boots. |
| **Fighting style** | Scrappy brawler — boxing-derived punches, hard low kicks. No flash, all function. |
| **Personality** | Calm, dry, protective of his town. |

**Stats (baseline — tune in `resources/`):**
- Max HP: 100
- Walk speed: 120 px/s (X), 80 px/s (Y-depth)
- Jump: ~0.6 s airtime
- Combo damage: punch 1 = 6, punch 2 = 6, punch 3 (finisher) = 12 + knockdown
- Jump kick: 10 + knockdown

**Required animations** (names are canonical — use these exact animation names in `SpriteFrames`):
`idle`, `walk`, `attack_1`, `attack_2`, `attack_3`, `jump`, `jump_kick`, `hurt`,
`knockdown`, `getup`, `death`, `victory`

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
| **Marta "The Crane" Kovac** — dockworker turned enforcer, wields a boat hook | 2 — Harbour | Long horizontal reach; slow but hits hard; occasionally pulls a shipping-crate swing that sweeps a lane (dodge via Y-depth movement). Teaches: use the depth axis. |
| **Victor Bayshore** — syndicate leader, final boss at the Mill Dam | 3 — Mill Dam | Two phases: (1) brawler with combo strings; (2) at 50% HP, enrages — faster, adds a charging grab. Arena hazard: slippery wet edge near the dam (visual only in v1). |

Boss HP baseline: 200 / 250 / 350. Bosses cannot be stun-locked: after 3 consecutive
hits taken, boss gains brief hyper-armor and counterattacks.

---

## 4. Gameplay Design

### 4.1 Core loop
Walk right → invisible trigger locks the camera and spawns an enemy wave →
defeat everyone in the wave → "GO →" indicator flashes → camera unlocks →
repeat → boss arena → boss fight → stage clear score tally → next stage.

### 4.2 Combat spec (v1 — simple core)

**Player moveset:**
- **Attack (single button):** pressing repeatedly chains a 3-hit combo
  (`attack_1` → `attack_2` → `attack_3`). Chain window: next press must land within
  0.4 s after a hit connects, else combo resets. Hit 3 causes knockdown.
- **Jump:** vertical hop; no horizontal air control change (moves with pre-jump velocity).
- **Jump kick:** attack while airborne. Knocks down on hit.
- **Movement:** 8-directional on the ground plane (X = along street, Y = depth).

**Hit rules:**
- Attacks connect only if attacker and target overlap in X (hitbox) **and** are within
  a **Y-depth band of ±12 px**.
- Confirmed player hits alternate `punch1` / `punch2` SFX. A hit that reduces an
  enemy to 0 HP plays `punch3` instead; misses and rejected invulnerable hits are silent.
- **Hitstun:** non-knockdown hits freeze the victim in `hurt` for 0.3 s and interrupt
  their action (except armored hits, see Thug/bosses).
- **Knockdown:** victim falls, is invulnerable while down and during `getup`
  (total ~1.2 s). Enemies can be juggled *into* knockdown but not while down.
- **Hit-pause:** on every connected hit, freeze both parties 2–3 frames (game feel — Phase 6).
- **Player invincibility:** 1.0 s of i-frames (sprite flicker) after getting up from a knockdown.

**Enemy AI states** (shared FSM, per-enemy tuning): `SPAWN → APPROACH → ATTACK → RECOVER → (RETREAT | CIRCLE) → APPROACH …` plus reactive `HURT`, `KNOCKDOWN`, `DEATH`.
Global rule: **max 2 enemies in ATTACK state simultaneously** (classic brawler courtesy
rule); others CIRCLE at a standoff radius.

**Pickups** (dropped from breakable props: trash cans, crates, hydro boxes):
- **Coffee** ("Timbo's" cup): +25 HP
- **Poutine:** full heal (rare)
- **Cash / loonie stack:** +500 / +100 points

**Lives & continues:** 3 lives per credit, 3 continues. Death → lose life, respawn in
place with full HP and 2 s of i-frames. Out of continues → Game Over screen → high score.

**Scoring:** per-enemy points (Punk 100, Knife Punk 150, Biker 200, Thug 300,
bosses 2000+), pickups, stage-clear bonus = remaining HP × 10. High score persisted
to `user://save.cfg`.

### 4.3 Explicitly deferred (stretch — do NOT build in v1)
Grabs/throws, weapon pickups, special/desperation moves, run/dash, local co-op,
extra playable characters, difficulty settings.

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

### Stage 2 — "The Harbour" (Waterfront & grain elevators)
- **Look:** Dusk. Docks, moored fishing boats, stacked shipping containers, the towering grain elevators silhouetted against Georgian Bay. Parallax: bay water + elevators / containers / dock planking.
- **Enemies:** Punk (red swap), Thug, Biker debut. Waves: (2 Punks + 1 Thug) → (2 Bikers) → (1 Thug + 2 Knife Punks) → (2 Thugs) → mini-gauntlet (1 of each).
- **Boss:** Marta "The Crane" Kovac, on the main pier.
- **Music mood:** Tense bass-heavy groove, industrial percussion.
- **Teaches:** depth-axis dodging (Biker charges, Marta's sweeps), armor enemies.

### Stage 3 — "Harrison Park to the Mill Dam" (Finale)
- **Look:** Two visual segments: (a) Harrison Park — autumn trees, the Sydenham River, a footbridge; (b) the Mill Dam — rushing water, fish ladder, floodlights. Parallax: treeline/river → dam structure.
- **Enemies:** All types + toughest palette swaps. Waves: (3 mixed) → (2 Thugs + Biker) → (2 Bikers + 2 Knife Punks) → footbridge chokepoint fight (narrow Y-band!) → pre-boss gauntlet.
- **Boss:** Victor Bayshore, two phases, at the dam.
- **Music mood:** Urgent, climactic; phase-2 tempo shift.
- **Teaches:** mastery test; the footbridge fight deliberately constrains the depth axis.

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
`move_right_p1`, `move_up_p1`, `move_down_p1`, `attack_p1`, `jump_p1`, plus global
`pause`. Player scenes take an exported `player_index: int`; input reads
`"%s_p%d" % [action, player_index]`. Adding P2 later = new bindings + spawn, no rework.

Default bindings: Arrows/WASD + `Z`/`J` attack + `X`/`K` jump; gamepad D-pad/stick +
face buttons. Camera and HUD are written against "list of players" (length 1 for now).

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

### Phase 5 — Stages 2 & 3
- [x] **Thug** and **Biker** enemies (armor + charge behaviours); palette-swap resources.
- [x] `stage_2.tscn` harbour: art, waves, **Boss 2 (Marta)** with lane-sweep attack.
- [x] `stage_3.tscn` park→dam: art (two segments), footbridge narrow-band fight, waves.
- [x] **Boss 3 (Victor Bayshore)** two-phase AI; ending text card.
- [x] Poutine pickup; anti-stunlock boss armor rule (§3.3).
- [x] **DoD:** full 3-stage campaign playable start-to-finish.

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
> - `stage_2.tscn` is a 5120×480 dusk harbour built from layered project-native
>   shapes: Georgian Bay, grain elevators, boats, cranes, container yards, dock
>   planking and the Bayshore Freight boss pier. Five `WaveData` resources encode
>   the exact §5 lineups, including Red Punk and Dock Thug stat overrides; runtime
>   verification observed 3/2/3/2/4 enemies with the expected types and values.
> - Marta is a 250 HP / 14 damage / 2500 point boss with a 148 px boat-hook strike
>   and a clearly marked shipping-crate sweep. The sweep deals 18 + knockdown in an
>   18 px depth band: a same-lane probe lost exactly 18 HP while a 42 px Y dodge took
>   zero. Her third quick hit routes Hurt → Hurt → armored Counter; the HUD now reads
>   boss names from `EnemyStats`, so both Slick Rick and Marta label correctly.
> - The campaign shell includes the Stage 2 story card and scene. Verification
>   loaded it through `MainFlow`, defeated Marta to reach `STAGE 2 CLEAR` with the
>   exact HP×10 bonus, and advanced into the Stage 3 card. Boss defeat awarded 2500
>   points, hid the boss bar, and retained the arena camera lock during the tally.
> - `stage_3.tscn` is a 5120×480 project-native composition with two distinct visual
>   segments: autumn Harrison Park and the Sydenham River lead across a timber
>   footbridge into the concrete, rushing-water, fish-ladder and floodlight Mill Dam
>   arena. Five `WaveData` resources produced the exact 3/3/4/3/4 lineups. Wave 4
>   constrained Sean and every enemy to y ∈ [232, 250], then restored y ∈ [204, 280]
>   and unlocked the camera atomically on clear.
> - Victor Bayshore is a 350 HP / 4000 point final boss. Phase 1 uses an 8+8+12
>   three-hit string; crossing 50% HP enters an invulnerable enrage, boosts movement
>   by 30%, changes the string to 10+10+14, and enables a 410 px/s charging grab for
>   18 + knockdown. A missed charge leaves a verified 1.0 s punish window. Three
>   quick incoming hits force an armored 12 + knockdown Counter, and the armor clears
>   after recovery. Victor reuses the licensed boss sheet with a distinct data tint
>   and aura; no additional art license was introduced.
> - The rare poutine drops from the pre-boss crate and fully heals. Runtime validation
>   broke the configured crate, observed one `poutine` pickup, healed Sean from 7 to
>   100, and displayed `POUTINE  FULL HEAL` on the HUD.
> - Finale verification defeated Victor through the normal Death state, awarded 4000
>   points plus an exact 73 HP × 10 bonus for a 4730 total, showed `STAGE 3 CLEAR`,
>   advanced to the `QUIET WATER` ending, removed the stage, and returned to title
>   with an actual Z press. A separate single-run routing probe traversed the three
>   intro cards, Stage1 → Stage2 → Stage3, all three clear states, and the ending.
>   The final run had no current-run errors and a clean game log; park, bridge, dam,
>   Victor and ending visuals were screenshot-checked.

### Phase 6 — Audio & polish
- [x] Music per stage + title + boss stinger (free packs, credited); `AudioManager` crossfades.
  **The persistent two-player `AudioManager` crossfades every flow cue. Stage 1 uses
  the supplied MP3; title, Stages 2–3, boss, clear, Game Over and ending each use a
  distinct loopable 11.025 kHz project-native chiptune composition generated from
  authored melody/bass/drum profiles. Runtime verification cycled all eight cues,
  confirmed their identities and unique lengths, sought across a generated loop
  boundary without playback stopping, and activated the Stage 1 boss gate to prove
  that `boss_stinger` and the boss cue fire together. Current-run errors and the
  current game log were clean.**
- [x] SFX: hits, whiffs, knockdown, breakables, pickups, UI.
  **Confirmed hits retain the supplied `punch1` / `punch2` alternation and `punch3`
  for defeating blows. `AudioManager` now generates six license-free 16-bit mono
  cues at runtime and serves them from an eight-player pool. Verification proved a
  missed ground swing emitted `whiff` while a 6-damage confirmed swing played the
  recorded punch without a whiff; breaking a prop, collecting its Coffee, triggering
  knockdown, pressing Z through the intro, and pausing with Esc emitted `breakable`,
  `pickup`, `knockdown`, `ui_confirm`, and `ui_pause` respectively.**
- [x] Game feel: hit-pause (2–3 frames), light screen shake on knockdowns, sprite flash on hit, i-frame flicker.
  **`ImpactManager` now applies an unscaled 0.04/0.055 s connected-hit pause and
  extends overlapping pauses safely. Normal-hit verification dealt exactly 6 damage,
  flashed the victim to 2.2× white, and restored time scale/colour to normal.
  Knockdowns additionally produced a 4 px camera offset that settled back to zero;
  the existing post-getup i-frame flicker remains active.**
- [x] Balance pass: play full campaign, tune HP/damage/wave sizes in resources.
  **The complete player/enemy/boss/pickup/wave resource audit found the authored
  values internally consistent, so they were retained instead of changed without
  evidence. A repeatable normal-combat autoplay run cleared all three stages with
  five deaths and one continue used: Stage 1 ended at 85 HP / 2 lives, Stage 2 at
  100 HP / 3 lives after the continue, and Stage 3 at 42 HP / 1 life. It finished
  at 19,920 points with a clean current game log, demonstrating rising pressure and
  a beatable finale even for a simple approach-and-mash strategy.**
- [ ] **DoD:** full run feels punchy; no silent actions; campaign beatable but challenging (~2–4 continues for an average player).

### Phase 7 — Release
- [ ] Windows export preset (embedded PCK), icon, project name/version.
- [x] Web export preset + GitHub Pages deployment (completed early after Phase 3;
  CI export and live browser controls verified).
- [ ] Final `CREDITS.md` audit + in-game credits screen.
- [ ] Playtest export build outside the editor; fix export-only issues.
- [ ] **DoD:** distributable zip that runs on a clean Windows machine.

### Stretch phases (post-v1, in rough priority order)
- [ ] **S1 — Local co-op:** P2 bindings, second player spawn, camera avg of players, shared lives pool.
- [ ] **S2 — Grabs & throws:** grab on walk-into-enemy, forward/back throw, throw damage to other enemies on landing.
- [ ] **S3 — Weapons:** pipe/knife/hockey-stick pickups with durability.
- [ ] **S4 — Special move:** health-cost crowd-clearer (classic SoR special).
- [ ] **S5 — Run/dash + dash attack.**
- [ ] **S6 — Second playable character; difficulty settings; arcade score attack mode.**

---

## 9. Working Agreements (for AI tools & humans)

### Tooling
- **Godot editor MCP (`godot-ai`) is available** and preferred for: creating/editing scenes and nodes, setting project settings, input map, running the game (`project_run`), reading logs (`logs_read`), and screenshots for visual verification.
- Plain file edits are fine for `.gd` scripts, `.tres` resources, and docs; after external file edits, let the editor rescan before running.
- **After any gameplay change, actually run the game** (test scene or stage) and verify behaviour — via MCP run + logs/screenshot, or ask the user to play. Don't mark roadmap items done on "it compiles."

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
