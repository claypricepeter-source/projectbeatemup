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

### Notes on Clay Character
- Used for Sean's current visuals. The supplied atlas and individual source frames
  remain in `assets/sprites/player/clay_character_godot/clay_character/`.
- Frames use 256×192 canvases with a supplied feet anchor at (128, 176). Sean renders
  at native 1× scale with the sprite node offset 80 px above the gameplay origin.
- Gameplay's canonical animations are mapped to the supplied moves at runtime:
  `attack_1`/`attack_2`/`attack_3` use light punch/strong punch/strong kick,
  `jump_kick` uses flying knee, and the dedicated hit/knockdown artwork supplies
  `hurt`, `knockdown`, `getup`, and `death`.

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
| Synthesized chiptune score | Project-native runtime synthesis | Original generated waveforms; no external asset | Distinct title, Stage 2, Stage 3, boss, clear, Game Over and ending loops |
| Player punch sounds (`punch1.mp3`, `punch2.mp3`, `punch3.mp3`) | User-provided project audio | Provided by the project owner for use in this game | Confirmed player hits; `punch3` is reserved for enemy-defeating blows |
| Synthesized gameplay/UI cues | Project-native runtime synthesis | Original generated waveforms; no external asset | Boss stinger, whiffs, knockdowns, breakables, pickups, confirm and pause cues |

The runtime-synthesized score and SFX introduce no new asset license.

## Fonts
The Phase 4 UI currently uses Godot's built-in font. A credited pixel font remains
an optional Phase 6 polish item.
