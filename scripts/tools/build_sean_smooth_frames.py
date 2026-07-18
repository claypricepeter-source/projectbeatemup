"""Build ten-frame Sean idle and combo loops from the generated atlas."""

from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
ATLAS_PATH = (
    PROJECT_ROOT
    / "assets/_source_packs/generated-sean-smooth/sean_idle_combo_atlas_alpha.png"
)
OUTPUT_ROOT = PROJECT_ROOT / "assets/sprites/player/sean_smooth"
CANVAS_SIZE = (256, 192)
CELL_SIZE = 256
FEET_Y = 176
TARGET_HEIGHT = 148
TARGET_WIDTH = 224


def _cells_for_rows(first_row: int) -> list[tuple[int, int]]:
    """Read the generated 6-column rows as a ten-frame row-major sequence."""
    return [(column, first_row) for column in range(6)] + [
        (column, first_row + 1) for column in range(4)
    ]


ANIMATIONS = {
    "idle": _cells_for_rows(0),
    "combo": _cells_for_rows(2),
}


def main() -> None:
    atlas = Image.open(ATLAS_PATH).convert("RGBA")
    if atlas.size != (1536, 1024):
        raise ValueError(f"Unexpected atlas size: {atlas.size}")

    for animation, cells in ANIMATIONS.items():
        output_dir = OUTPUT_ROOT / animation
        output_dir.mkdir(parents=True, exist_ok=True)
        for frame_index, (column, row) in enumerate(cells, start=1):
            cell = atlas.crop(
                (
                    column * CELL_SIZE,
                    row * CELL_SIZE,
                    (column + 1) * CELL_SIZE,
                    (row + 1) * CELL_SIZE,
                )
            )
            bounds = cell.getchannel("A").getbbox()
            if bounds is None:
                raise ValueError(f"Empty {animation} frame {frame_index}")
            sprite = cell.crop(bounds)
            scale = min(
                TARGET_HEIGHT / float(sprite.height),
                TARGET_WIDTH / float(sprite.width),
            )
            size = (
                max(1, round(sprite.width * scale)),
                max(1, round(sprite.height * scale)),
            )
            sprite = sprite.resize(size, Image.Resampling.NEAREST)
            canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
            position = ((CANVAS_SIZE[0] - size[0]) // 2, FEET_Y - size[1])
            canvas.alpha_composite(sprite, position)
            canvas.save(output_dir / f"{animation}{frame_index}.png")


if __name__ == "__main__":
    main()
