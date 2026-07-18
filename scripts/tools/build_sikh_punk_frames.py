"""Build Godot-ready Sikh Punk frames from the generated chroma-key atlas."""

from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
ATLAS_PATH = (
    PROJECT_ROOT
    / "assets/_source_packs/generated-sikh-punk/sikh_punk_atlas_alpha.png"
)
OUTPUT_ROOT = PROJECT_ROOT / "assets/sprites/enemies/sikh_punk"
CANVAS_SIZE = (160, 128)
FEET_Y = 122
FRAME_SCALE = 0.455
X_EDGES = (0, 314, 627, 940, 1254)
ROW_WINDOWS = ((10, 290), (305, 575), (585, 860), (875, 1180))
ANIMATIONS = ("idle", "walk", "punch", "hurt")


def main() -> None:
    atlas = Image.open(ATLAS_PATH).convert("RGBA")
    if atlas.size != (1254, 1254):
        raise ValueError(f"Unexpected atlas size: {atlas.size}")

    for row, animation in enumerate(ANIMATIONS):
        output_dir = OUTPUT_ROOT / animation
        output_dir.mkdir(parents=True, exist_ok=True)
        top, bottom = ROW_WINDOWS[row]
        for column in range(4):
            cell = atlas.crop((X_EDGES[column], top, X_EDGES[column + 1], bottom))
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
            canvas.save(output_dir / f"{animation}{column + 1}.png")


if __name__ == "__main__":
    main()
