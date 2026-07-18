# Credits & Asset Attribution

Every asset pack used in Project Beatemup is recorded here. Rules (see AGENTS.md §6.2):
verify license before import, keep untouched originals in `assets/_source_packs/`,
add the entry here the moment a pack is imported.

## Art

| Pack | Author | Source | License | Status |
|---|---|---|---|---|
| Streets of Fight (free version) | ansimuz | https://ansimuz.itch.io/streets-of-fight | Free for personal/commercial game use; modification allowed; do not re-distribute the raw files as an asset pack | **IMPORTED** — license page rechecked 2026-07-15; source pack retained locally and only packaged game exports may be published |
| Magneto Pride Boss (`magneto_boss_codex_assets`) | User-provided project art | Local asset pack; original source URL not supplied | Permission/source terms not included with the pack | **IMPORTED FOR LOCAL DEVELOPMENT** — confirm provenance and redistribution permission before the next public export |
| Clay Character (`clay_character_godot`) | User-provided AI-generated project art | Local asset folder; original source URL not supplied | Permission/source terms not included with the folder | **IMPORTED FOR LOCAL DEVELOPMENT** — confirm provenance and redistribution permission before the next public export |
| Sean smooth idle/combo atlas | Project-generated pixel art based on user-provided Sean references and a ten-frame fighting-game GIF timing reference | Generated for this project with OpenAI image generation; chroma source retained under `assets/_source_packs/generated-sean-smooth/` | User-directed generated asset; source-character/image rights not independently verified | **IMPORTED FOR LOCAL DEVELOPMENT** — active ten-frame idle and combo; confirm reference-image rights before public redistribution |
| Industrial arena sheet (`196124.png`, marked "MICA") | User-provided project art | Local sprite sheet; original game/source URL not supplied | Permission/source terms not included with the image | **IMPORTED FOR LOCAL DEVELOPMENT** — used for Stage 2; confirm provenance and redistribution permission before the next public export |
| Stage 2 wall decals (Tim Hortons branding, Pakistan flag, Brampton road sign) | User-provided reference images | Local image set; original source URLs not supplied | Permission and trademark-clearance status not supplied | **IMPORTED FOR LOCAL DEVELOPMENT** — clear all branding and image rights before public redistribution |
| Curry powder package prop | User-provided reference image | Local image; original source URL not supplied | Permission/source terms not supplied | **IMPORTED FOR LOCAL DEVELOPMENT** — white background removed for the floating Stage 2 acid prop; confirm image rights before public redistribution |
| Sikh Punk enemy atlas | Project-generated pixel art based on a user-provided portrait reference | Generated for this project with OpenAI image generation; chroma source retained under `assets/_source_packs/generated-sikh-punk/` | User-directed generated asset; likeness/source-photo permission not independently verified | **IMPORTED FOR LOCAL DEVELOPMENT** — replaces standard Punk and Red Punk visuals; confirm likeness and reference-photo rights before public redistribution |
| Ragnaros stinkhorn boss atlas | Project-generated pixel art based on user-provided character-sheet and creature references | Generated and corrected for this project with OpenAI image generation; chroma sources retained under `assets/_source_packs/generated-ragnaros-mushroom/` | User-directed generated asset; source-character/image rights not independently verified | **IMPORTED FOR LOCAL DEVELOPMENT** — Stage 2 boss with a generated flaming common-stinkhorn weapon and fused fleshy ammunition reservoir; confirm reference-image and character rights before public redistribution |

### Notes on Sikh Punk
- Sixteen transparent 160×128 frames provide four-frame `idle`, `walk`, `attack`
  and `hurt` animations with a consistent feet anchor at y=122.
- Only `punk.tscn` uses this generated atlas. Knife Punk and Thug retain the
  original licensed Streets of Fight frames.

### Notes on Ragnaros Stinkhorn Boss
- Forty transparent 256×192 frames provide eight-frame `idle`, `walk`, `attack`,
  `hurt` and `taunt` animations with a consistent fiery feet anchor at y=184.
- The corrected weapon is a claymore-sized, flexible, dark-brown flaming common
  stinkhorn (*Phallus impudicus*) with a narrow honeycombed conical head. No broad
  umbrella cap, hammer, mace, hook, or conventional sword remains visible.
- A later generated edit replaces the hanging pouch with a large, soft-lobed,
  dark-brown fleshy reservoir broadly fused to the weapon underside near its grip.
  The supplied creature image was used only as a silhouette and surface-anatomy reference.
- The constant pixel ember vortex, long-tailed milky liquid projectiles and orbiting
  dizzy stars are project-native Godot
  drawing code and introduce no additional raster asset or license.

### Notes on Clay Character
- Used for Sean's current visuals. The supplied atlas and individual source frames
  remain in `assets/sprites/player/clay_character_godot/clay_character/`.
- Frames use 256×192 canvases with a supplied feet anchor at (128, 176). Sean renders
  at native 1× scale with the sprite node offset 80 px above the gameplay origin.
- Gameplay's canonical animations are mapped to the supplied moves at runtime:
  `attack_1`/`attack_2`/`attack_3` use light punch/strong punch/strong kick,
  `jump_kick` uses flying knee, and the dedicated hit/knockdown artwork supplies
  `hurt`, `knockdown`, `getup`, and `death`.
- Sean's active idle and ground combo are replaced at runtime by the generated
  ten-frame refinement in `assets/sprites/player/sean_smooth/`; all other supplied
  Clay animations remain available unchanged.

### Notes on Magneto Pride Boss
- Used for Slick Rick's current visuals and as the recoloured/aura-backed base for
  Victor Bayshore; original uniform PNGs remain untouched.
- The in-game resource follows `sprite_manifest.json`: 384×224 canvases, pivot
  (192, 212), authored frame order/FPS, nearest filtering, and no mipmaps.
- Rainbow Meteor and the throw victim use separate render layers as required by
  the supplied implementation notes.

### Notes on Streets of Fight
- Designed for ~240px-tall stages with ~47px-tall character sprites.
- **Project convention:** render these sprites at 2× scale in our 640×360 viewport
  (set `scale = (2, 2)` on the sprite node or pre-scale sheets 2× nearest-neighbour),
  giving ~94px characters. Backgrounds likewise 2×. Never scale by non-integer factors.
- Free version characters/enemies get recolours to fit our cast (Sean = dark teal shirt).

## Audio

| Track | Author / source | License / permission | Use |
|---|---|---|---|
| Stage 1 Theme (`AUDIO-2026-03-12-18-11-23.mp3`) | User-provided project audio | Provided by the project owner for use in this game | Stage 1 music |
| Stage 2 Theme (`stage 2.mp3`) | User-provided project audio | Provided by the project owner for use in this game | Stage 2 music |
| Synthesized chiptune score | Project-native runtime synthesis | Original generated waveforms; no external asset | Distinct title, Stage 3, boss, clear, Game Over and ending loops |
| Player punch sounds (`punch1.mp3`, `punch2.mp3`, `punch3.mp3`) | User-provided project audio | Provided by the project owner for use in this game | Confirmed player hits; `punch3` is reserved for enemy-defeating blows |
| Sean death sound (`deathsean.mp3`) | User-provided project audio | Provided by the project owner for use in this game | Plays once at the start of Sean's life-loss KO sequence |
| Pool spreading sound (`after_death.mp3`) | User-provided project audio | Provided by the project owner for use in this game | Begins when Sean lands and the brown pool starts spreading |
| Synthesized gameplay/UI cues | Project-native runtime synthesis | Original generated waveforms; no external asset | Boss stinger, whiffs, knockdowns, breakables, pickups, confirm and pause cues |

The runtime-synthesized score and SFX introduce no new asset license.

## Fonts
The Phase 4 UI currently uses Godot's built-in font. A credited pixel font remains
an optional Phase 6 polish item.
