"""Build Godot-ready boss frames from the generated mushroom atlas."""

from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
ATLAS_PATH = (
    PROJECT_ROOT
    / "assets/_source_packs/generated-ragnaros-mushroom/ragnaros_stinkhorn_fleshy_sack_atlas_alpha.png"
)
OUTPUT_ROOT = PROJECT_ROOT / "assets/sprites/bosses/ragnaros_mushroom"
CANVAS_SIZE = (256, 192)
FEET_Y = 184
FRAME_SCALE = 0.66
X_EDGES_BY_ROW = (
    (0, 302, 599, 912, 1254),
    (0, 295, 598, 928, 1254),
    (0, 241, 592, 925, 1254),
    (0, 274, 626, 938, 1254),
)
ROW_Y_WINDOWS = ((0, 290), (290, 590), (590, 910), (910, 1254))
ANIMATIONS = ("idle", "walk", "attack", "hurt")


def _vortex_variant(canvas: Image.Image, phase: int) -> Image.Image:
    """Add a small stepped swirl to the lower flame cyclone between key poses."""
    result = canvas.copy()
    source = canvas.copy()
    for y in range(104, CANVAS_SIZE[1]):
        band = (y - 104) // 6
        offset = ((band + phase) % 5) - 2
        if offset == 0:
            continue
        strip = source.crop((0, y, CANVAS_SIZE[0], y + 1))
        result.paste((0, 0, 0, 0), (0, y, CANVAS_SIZE[0], y + 1))
        result.alpha_composite(strip, (offset, y))
    return result


def main() -> None:
    atlas = Image.open(ATLAS_PATH).convert("RGBA")
    if atlas.size != (1254, 1254):
        raise ValueError(f"Unexpected atlas size: {atlas.size}")

    for row, animation in enumerate(ANIMATIONS):
        output_dir = OUTPUT_ROOT / animation
        output_dir.mkdir(parents=True, exist_ok=True)
        x_edges = X_EDGES_BY_ROW[row]
        top, bottom = ROW_Y_WINDOWS[row]
        base_frames: list[Image.Image] = []
        for column in range(4):
            cell = atlas.crop(
                (
                    x_edges[column],
                    top,
                    x_edges[column + 1],
                    bottom,
                )
            )
            bounds = cell.getchannel("A").getbbox()
            if bounds is None:
                raise ValueError(f"Empty frame at row {row}, column {column}")
            sprite = cell.crop(bounds)
            size = (
                max(1, round(sprite.width * FRAME_SCALE)),
                max(1, round(sprite.height * FRAME_SCALE)),
            )
            sprite = sprite.resize(size, Image.Resampling.NEAREST)
            canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
            position = ((CANVAS_SIZE[0] - size[0]) // 2, FEET_Y - size[1])
            canvas.alpha_composite(sprite, position)
            base_frames.append(canvas)
        for column, canvas in enumerate(base_frames):
            frame_number = column * 2 + 1
            canvas.save(output_dir / f"{animation}{frame_number}.png")
            _vortex_variant(canvas, column + row).save(
                output_dir / f"{animation}{frame_number + 1}.png"
            )

    taunt_dir = OUTPUT_ROOT / "taunt"
    taunt_dir.mkdir(parents=True, exist_ok=True)
    hurt_frames = [
        Image.open(OUTPUT_ROOT / "hurt" / f"hurt{index}.png").convert("RGBA")
        for index in (1, 3, 5, 7, 5, 3, 1, 3)
    ]
    for index, frame in enumerate(hurt_frames, start=1):
        _vortex_variant(frame, index + 2).save(taunt_dir / f"taunt{index}.png")


if __name__ == "__main__":
    main()
