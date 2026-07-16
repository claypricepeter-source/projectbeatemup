# Magneto Pride Boss — Codex Asset Pack

## Contents

- `frames_uniform/`: 32 transparent PNG frames on identical 384×224 canvases.
- `frames_tight/`: The same frames cropped tightly around their visible pixels.
- `sprite_manifest.json`: Animation order, frame timing, pivots, and file paths.
- `reference/contact_sheet.png`: Visual QA sheet.
- `reference/original_sprite_sheet.png`: Original source.
- `reference/portrait.png`: Character portrait.
- `reference/boss_intro_reference.png`: Intro artwork reference.

## Import settings

- Texture filtering: Nearest / Point.
- Mipmaps: Disabled.
- Pixel snapping: Enabled.
- Default pivot: (192, 212).
- Default facing direction: Right.
- Flip horizontally for left-facing movement.

## Layered animations

### Rainbow Meteor

Frames 0–1 contain the character.
Frames 2–5 contain the meteor impact effect.

For a complete in-game animation, hold character frame 1 and play frames 2–5
on a separate visual-effects layer.

### Throw

`throw_000.png` contains the boss and the first victim position.
`throw_001_victim_overlay.png` contains only the airborne victim.

Keep the boss pose from frame 0 visible while moving or displaying the victim
overlay as a separate entity.

## Codex instruction

Read `sprite_manifest.json` before implementing the character. Do not infer
frame boundaries from the original presentation sheet. Use the files in
`frames_uniform/` in the listed order.
