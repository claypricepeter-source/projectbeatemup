# Clay — Godot 4 sprite pack

This folder contains transparent, individually labeled PNG frames extracted from the supplied Mortal-Kombat-style reference sheet.

## Fast setup

1. Copy the entire `clay_character` folder into the root of your Godot project so the paths begin with `res://clay_character/`.
2. Drag `godot/ClayCharacter.tscn` into a scene, or assign `godot/clay_sprite_frames.tres` to an `AnimatedSprite2D`.
3. Keep texture filtering set to **Nearest** and mipmaps disabled for crisp pixel art.

## Included

- `sprites/` — individual transparent PNGs, organized and labeled by animation.
- `atlas/clay_atlas.png` — runtime-friendly atlas containing every 256×192 frame.
- `godot/clay_sprite_frames.tres` — ready-to-use Godot 4 `SpriteFrames` resource.
- `godot/ClayCharacter.tscn` — ready-to-instance `AnimatedSprite2D` scene.
- `godot/clay_character.gd` — small helper script with `play_action()`.
- `data/animations.json` — frame counts, speed, loop flags, and filenames.
- `preview/extracted_contact_sheet.png` — visual QA sheet.
- `source/original_sprite_sheet.png` — untouched source.

## Alignment

Every individual frame is **256×192 px** with a shared character anchor at **x=128** and ground baseline at **y=176**. This prevents the usual frame-to-frame jitter caused by individually trimmed sprites.

## Animation names

`idle, walk, run, jump, crouch_block, light_punch, strong_punch, light_kick, strong_kick, combo, burning_uppercut, power_forearm, spinning_backfist, flying_knee, throw, get_hit, knocked_down, victory, defeat, fatality, taunts`

## Godot import recommendations

Select `atlas/clay_atlas.png` in Godot's FileSystem panel and use:

- Filter: Off
- Mipmaps: Off
- Compression mode: Lossless
- Repeat: Disabled

Then click **Reimport**. The included scene also requests nearest-neighbour filtering at runtime.

## Notes

The source is an AI-generated presentation sheet rather than a purpose-built production sprite sheet. The extractor removes the dark panel background and separates the visible poses, but a few complex multi-character/effect frames may still benefit from manual pixel cleanup before final release.
