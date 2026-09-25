"""Build Sean's unified SoR2 sprite set from the two existing source sets.

Problems this fixes (see AGENTS.md §8 Phase 8 art notes):
  * The "smooth" set draws Sean ~148 px tall, the Clay pack ~113 px, so every
    move that borrowed a Clay animation shrank him mid-combo.
  * Frames carry cut-out debris, baked-in label text and blood speckles.
  * Clay frames float or sink by up to 15 px between frames.
  * Knockdown ended standing up while the body lay on the floor, and there
    was no real get-up; the Clay throw frames contain a second character.

Output: assets/sprites/player/sean_sor2/<anim>/<anim>_NN.png (256x192, feet
anchored at (128, 176), one shared palette) and sean_sor2_frames.tres.
Source folders are never modified. Run from the project root:
    python scripts/tools/build_sean_sor2_frames.py
"""
from __future__ import annotations

import os
import re
import shutil
from collections import deque

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SMOOTH = os.path.join(ROOT, "assets/sprites/player/sean_smooth")
CLAY = os.path.join(ROOT, "assets/sprites/player/clay_character_godot/clay_character/sprites")
OUT_DIR = os.path.join(ROOT, "assets/sprites/player/sean_sor2")
RES_DIR = "res://assets/sprites/player/sean_sor2"

CANVAS = (256, 192)
ANCHOR = (128, 176)
# Final standing height. The smooth set is drawn 148 px tall; the Clay pack's
# body proportions are ~12% smaller than the smooth set at equal height (its
# idle frames are clipped at the boots), so Clay frames are enlarged to match.
TARGET_HEIGHT = 113
SMOOTH_HEIGHT = 148
CLAY_SCALE = 1.12
PALETTE_SIZE = 64
# Components smaller than this (in source pixels) are debris or label text.
MIN_COMPONENT = 40
# Components further than this from the body are removed whatever their size.
MAX_GAP = 10

# Animation table: name -> (frames, fps, loop, grounded)
# A frame is (set, source_anim, index). "grounded" snaps each frame's feet
# to the baseline; airborne and lying frames keep their authored height.
S, C = "smooth", "clay"
ANIMATIONS: dict[str, tuple[list[tuple[str, str, int]], float, bool, bool]] = {
    "idle": ([(S, "idle", i) for i in range(10)], 10.0, True, True),
    "walk": ([(S, "walk", i) for i in range(6)], 10.0, True, True),
    "light_punch": ([(S, "light_punch", i) for i in range(3)], 12.0, False, True),
    "strong_punch": ([(S, "strong_punch", i) for i in range(3)], 12.0, False, True),
    "strong_kick": ([(S, "strong_kick", i) for i in range(4)], 12.0, False, True),
    "light_kick": ([(C, "light_kick", i) for i in range(3)], 11.0, False, True),
    "flying_knee": ([(S, "flying_knee", i) for i in range(3)], 12.0, False, False),
    "jump": ([(S, "jump", i) for i in range(4)], 12.0, False, False),
    "hurt": ([(S, "hurt", i) for i in range(3)], 12.0, False, True),
    "knockdown_air": ([(S, "knockdown", 0), (S, "knockdown", 1)], 10.0, False, False),
    "knockdown": ([(S, "knockdown", 2), (S, "knockdown", 3)], 10.0, False, False),
    "getup": ([(S, "knockdown", 3), (S, "knockdown", 4), (S, "knockdown", 5)], 8.0, False, False),
    "death": ([(S, "knockdown", i) for i in range(4)], 8.0, False, False),
    "victory": ([(S, "victory", i) for i in range(4)], 6.0, True, True),
    "run": ([(C, "run", i) for i in range(9)], 12.0, True, True),
    "power_forearm": ([(C, "power_forearm", i) for i in range(3)], 12.0, False, True),
    "burning_uppercut": ([(C, "burning_uppercut", i) for i in range(4)], 12.0, False, True),
    "spinning_backfist": ([(C, "spinning_backfist", i) for i in range(3)], 12.0, False, True),
    "crouch_block": ([(C, "crouch_block", i) for i in range(9)], 12.0, False, True),
    # Clean grapple poses (the Clay throw frames contain a second character).
    "grab_hold": ([(S, "light_punch", 1)], 1.0, True, True),
    "throw": ([(S, "strong_punch", 0), (C, "spinning_backfist", 1),
               (C, "spinning_backfist", 2), (S, "strong_punch", 2)], 10.0, False, True),
}
# Canonical aliases the rest of the code base still names (AGENTS.md §3.1).
ALIASES = {
    "attack_1": "light_punch",
    "attack_2": "strong_punch",
    "attack_3": "strong_kick",
    "jump_kick": "flying_knee",
}


def source_path(kind: str, anim: str, index: int) -> str:
    if kind == S:
        return os.path.join(SMOOTH, anim, f"{anim}{index + 1}.png")
    return os.path.join(CLAY, anim, f"{anim}_{index:02d}.png")


def components(alpha: Image.Image) -> list[set[tuple[int, int]]]:
    w, h = alpha.size
    px = alpha.load()
    seen = [[False] * w for _ in range(h)]
    found = []
    for y in range(h):
        for x in range(w):
            if seen[y][x] or px[x, y] < 128:
                continue
            comp = set()
            queue = deque([(x, y)])
            seen[y][x] = True
            while queue:
                cx, cy = queue.popleft()
                comp.add((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and px[nx, ny] >= 128:
                            seen[ny][nx] = True
                            queue.append((nx, ny))
            found.append(comp)
    return found


def bbox(comp: set[tuple[int, int]]) -> tuple[int, int, int, int]:
    xs = [p[0] for p in comp]
    ys = [p[1] for p in comp]
    return min(xs), min(ys), max(xs), max(ys)


def gap(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> int:
    dx = max(a[0] - b[2], b[0] - a[2], 0)
    dy = max(a[1] - b[3], b[1] - a[3], 0)
    return max(dx, dy)


def is_backdrop(pixel: tuple[int, int, int, int]) -> bool:
    """Dark neutral grey left over from the Clay sheet's background."""
    r, g, b, a = pixel
    hi, lo = max(r, g, b), min(r, g, b)
    return a >= 128 and 9 <= hi <= 48 and hi - lo <= 12


def strip_backdrop(image: Image.Image) -> Image.Image:
    """Flood inward from the transparent outside through backdrop-grey pixels.
    The near-black outline (< 9) stops the fill, protecting the black tank top."""
    w, h = image.size
    px = image.load()
    seen = [[False] * w for _ in range(h)]
    queue = deque()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] < 128:
                seen[y][x] = True
                queue.append((x, y))
    while queue:
        cx, cy = queue.popleft()
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
                seen[ny][nx] = True
                if is_backdrop(px[nx, ny]):
                    px[nx, ny] = (0, 0, 0, 0)
                    queue.append((nx, ny))
    return image


def clean(image: Image.Image, clay: bool = False) -> Image.Image:
    """Keep the body plus sizeable effects touching it; drop debris/labels."""
    image = image.convert("RGBA")
    if clay:
        image = strip_backdrop(image)
    alpha = image.getchannel("A")
    comps = components(alpha)
    if not comps:
        return image
    body = max(comps, key=len)
    body_box = bbox(body)
    keep = set(body)
    for comp in comps:
        if comp is body or len(comp) < MIN_COMPONENT:
            continue
        if gap(bbox(comp), body_box) <= MAX_GAP:
            keep |= comp
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    src = image.load()
    dst = out.load()
    for x, y in keep:
        r, g, b, a = src[x, y]
        dst[x, y] = (r, g, b, 255)
    return out


def scale_about_anchor(image: Image.Image, factor: float) -> Image.Image:
    """Downsample around the feet anchor, then re-binarise alpha."""
    if abs(factor - 1.0) < 1e-3:
        return image
    w, h = image.size
    nw, nh = round(w * factor), round(h * factor)
    # Premultiply so transparent pixels do not bleed dark fringes.
    premult = Image.new("RGBA", image.size)
    src = image.load()
    dst = premult.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = src[x, y]
            dst[x, y] = (r * a // 255, g * a // 255, b * a // 255, a)
    small = premult.resize((nw, nh), Image.BOX if factor < 1.0 else Image.BICUBIC)
    sp = small.load()
    for y in range(nh):
        for x in range(nw):
            r, g, b, a = sp[x, y]
            if a < 110:
                sp[x, y] = (0, 0, 0, 0)
            else:
                sp[x, y] = (min(255, r * 255 // a), min(255, g * 255 // a), min(255, b * 255 // a), 255)
    out = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    ox = round(ANCHOR[0] - ANCHOR[0] * factor)
    oy = round(ANCHOR[1] - ANCHOR[1] * factor)
    out.alpha_composite(small, (ox, oy))
    return out


def ground(image: Image.Image) -> Image.Image:
    box = image.getbbox()
    if box is None:
        return image
    shift = ANCHOR[1] - box[3]
    if shift == 0:
        return image
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out.alpha_composite(image, (0, shift))
    return out


def head_center_x(image: Image.Image) -> float:
    """X centroid of the top 25% of the silhouette (head and shoulders)."""
    box = image.getbbox()
    if box is None:
        return ANCHOR[0]
    alpha = image.getchannel("A").load()
    top, bottom = box[1], box[1] + max(4, (box[3] - box[1]) // 4)
    total = count = 0
    for y in range(top, bottom):
        for x in range(box[0], box[2]):
            if alpha[x, y] >= 128:
                total += x
                count += 1
    return total / count if count else ANCHOR[0]


def build_frame(kind: str, anim: str, index: int, grounded: bool) -> Image.Image:
    image = clean(Image.open(source_path(kind, anim, index)), clay=kind == C)
    if kind == S:
        image = scale_about_anchor(image, TARGET_HEIGHT / SMOOTH_HEIGHT)
    else:
        image = scale_about_anchor(image, CLAY_SCALE)
    if grounded:
        image = ground(image)
    return image


def shift_x(image: Image.Image, dx: int) -> Image.Image:
    if dx == 0:
        return image
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out.paste(image, (dx, 0), image)
    return out


def main() -> None:
    frames: dict[str, list[Image.Image]] = {}
    idle_head = None
    for name, (sources, _fps, _loop, grounded) in ANIMATIONS.items():
        built = [build_frame(kind, anim, idx, grounded) for kind, anim, idx in sources]
        if name == "idle":
            idle_head = head_center_x(built[0])
        frames[name] = built

    # Clay animations were authored on a slightly different horizontal anchor:
    # shift each whole Clay animation so its first frame's head lines up with
    # idle (one shift per animation keeps the in-animation motion intact).
    for name, (sources, _fps, _loop, _grounded) in ANIMATIONS.items():
        if all(kind == C for kind, _a, _i in sources) and idle_head is not None:
            dx = round(idle_head - head_center_x(frames[name][0]))
            frames[name] = [shift_x(f, dx) for f in frames[name]]

    # One shared palette so both source sets read as the same sprite.
    all_frames = [f for fs in frames.values() for f in fs]
    mosaic = Image.new("RGB", (CANVAS[0] * 8, CANVAS[1] * ((len(all_frames) + 7) // 8)), (0, 0, 0))
    for i, f in enumerate(all_frames):
        bg = Image.new("RGB", CANVAS, (0, 0, 0))
        bg.paste(f, mask=f.getchannel("A"))
        mosaic.paste(bg, ((i % 8) * CANVAS[0], (i // 8) * CANVAS[1]))
    palette_img = mosaic.quantize(colors=PALETTE_SIZE, method=Image.Quantize.MEDIANCUT)

    if os.path.isdir(OUT_DIR):
        shutil.rmtree(OUT_DIR)
    os.makedirs(OUT_DIR)
    written: dict[str, list[str]] = {}
    for name, fs in frames.items():
        os.makedirs(os.path.join(OUT_DIR, name))
        paths = []
        for i, f in enumerate(fs):
            alpha = f.getchannel("A")
            rgb = Image.new("RGB", CANVAS, (0, 0, 0))
            rgb.paste(f, mask=alpha)
            quant = rgb.quantize(palette=palette_img, dither=Image.Dither.NONE).convert("RGBA")
            quant.putalpha(alpha.point(lambda a: 255 if a >= 128 else 0))
            rel = f"{name}/{name}_{i:02d}.png"
            quant.save(os.path.join(OUT_DIR, rel))
            paths.append(rel)
        written[name] = paths
    write_tres(written)
    print(f"built {sum(len(p) for p in written.values())} frames in {len(written)} animations")


def write_tres(written: dict[str, list[str]]) -> None:
    ext_ids: dict[str, str] = {}
    lines = []
    for name, paths in written.items():
        for rel in paths:
            ext_ids[rel] = f"{len(ext_ids) + 1}_{os.path.splitext(os.path.basename(rel))[0]}"
            lines.append(f'[ext_resource type="Texture2D" path="{RES_DIR}/{rel}" id="{ext_ids[rel]}"]')
    anims = []
    table = dict(ANIMATIONS)
    names = list(written) + list(ALIASES)
    for name in sorted(names):
        source = ALIASES.get(name, name)
        _src, fps, loop, _grounded = table[source]
        frame_entries = ",\n".join(
            '{\n"duration": 1.0,\n"texture": ExtResource("%s")\n}' % ext_ids[rel] for rel in written[source])
        anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}' % (
            frame_entries, "true" if loop else "false", name, fps))
    header = f"[gd_resource type=\"SpriteFrames\" load_steps={len(ext_ids) + 1} format=3]\n\n"
    body = "\n".join(lines) + "\n\n[resource]\nanimations = [" + ", ".join(anims) + "]\n"
    with open(os.path.join(OUT_DIR, "sean_sor2_frames.tres"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(header + body)


if __name__ == "__main__":
    main()
