from __future__ import annotations

import json
import math
import shutil
import zipfile
from pathlib import Path
from typing import Dict, List, Tuple

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

SOURCE = Path('/mnt/data/a_detailed_sprite_sheet_image_a_full_page_pixel_a.png')
OUT_ROOT = Path('/mnt/data/clay_character')
ZIP_PATH = Path('/mnt/data/clay_character_godot.zip')
CANVAS_W, CANVAS_H = 256, 192
ANCHOR_X = 128
BASELINE_Y = 176
ATLAS_COLS = 8

# Coordinates are in the source sheet. Centers are local x coordinates inside each panel.
ANIMS: Dict[str, dict] = {
    'idle': {
        'panel': (304, 18, 1168, 145),
        'centers': [52, 134, 218, 304, 394, 481, 568, 654],
        'fps': 6.0, 'loop': True, 'title_rects': [(0, 0, 100, 22)],
    },
    'walk': {
        'panel': (304, 150, 1168, 258),
        'centers': [52, 131, 204, 283, 360, 439, 524, 606, 690, 773],
        'fps': 10.0, 'loop': True, 'title_rects': [(0, 0, 90, 20)],
    },
    'run': {
        'panel': (304, 264, 1168, 365),
        'centers': [53, 156, 257, 360, 460, 564, 660, 752, 830],
        'fps': 12.0, 'loop': True, 'title_rects': [(0, 0, 70, 20)],
    },
    'jump': {
        'panel': (304, 371, 1168, 471),
        'centers': [43, 133, 230, 336, 442, 541, 643, 748],
        'fps': 10.0, 'loop': False, 'title_rects': [(0, 0, 80, 20)],
    },
    'crouch_block': {
        'panel': (304, 477, 1168, 554),
        'centers': [68, 158, 234, 311, 389, 466, 540, 617, 689],
        'fps': 8.0, 'loop': True, 'title_rects': [(0, 0, 150, 19)],
    },
    'light_punch': {
        'panel': (15, 559, 273, 681),
        'centers': [55, 174],
        'fps': 12.0, 'loop': False, 'title_rects': [(0, 0, 125, 24)],
    },
    'strong_punch': {
        'panel': (276, 559, 581, 681),
        'centers': [53, 145, 235],
        'fps': 12.0, 'loop': False, 'title_rects': [(0, 0, 150, 24)],
    },
    'light_kick': {
        'panel': (584, 559, 875, 681),
        'centers': [54, 152, 232],
        'fps': 11.0, 'loop': False, 'title_rects': [(0, 0, 120, 24)],
    },
    'strong_kick': {
        'panel': (878, 559, 1168, 681),
        'centers': [52, 140, 232],
        'fps': 11.0, 'loop': False, 'title_rects': [(0, 0, 140, 24)],
    },
    'combo': {
        'panel': (15, 686, 1168, 771),
        'centers': [48, 120, 192, 264, 337, 409, 482, 557, 651, 745],
        'fps': 14.0, 'loop': False, 'title_rects': [(0, 0, 90, 20)],
        'overlap': 10,
    },
    'burning_uppercut': {
        'panel': (15, 776, 307, 921),
        'centers': [32, 107, 190, 258],
        'fps': 12.0, 'loop': False, 'title_rects': [(0, 0, 190, 42)],
    },
    'power_forearm': {
        'panel': (310, 776, 581, 921),
        'centers': [47, 124, 220],
        'fps': 12.0, 'loop': False, 'title_rects': [(0, 0, 160, 42)],
    },
    'spinning_backfist': {
        'panel': (584, 776, 846, 921),
        'centers': [49, 155, 235],
        'fps': 12.0, 'loop': False, 'title_rects': [(0, 0, 190, 42)],
    },
    'flying_knee': {
        'panel': (849, 776, 1168, 921),
        'centers': [47, 133, 255],
        'fps': 12.0, 'loop': False, 'title_rects': [(0, 0, 130, 42)],
    },
    'throw': {
        'panel': (15, 925, 594, 1050),
        'centers': [63, 164, 270, 392, 512],
        'fps': 10.0, 'loop': False, 'title_rects': [(0, 0, 75, 22)],
        'overlap': 20,
    },
    'get_hit': {
        'panel': (598, 925, 1168, 1050),
        'centers': [41, 115, 192, 262, 336, 423, 517],
        'fps': 10.0, 'loop': False, 'title_rects': [(0, 0, 95, 22)],
    },
    'knocked_down': {
        'panel': (15, 1054, 1168, 1131),
        'centers': [90, 204, 337, 486, 658, 788, 934, 1082],
        'fps': 8.0, 'loop': False, 'title_rects': [(0, 0, 150, 20)],
        'overlap': 16,
    },
    'victory': {
        'panel': (15, 1135, 375, 1293),
        'centers': [60, 162, 245, 323],
        'fps': 6.0, 'loop': True, 'title_rects': [(0, 0, 95, 22)],
    },
    'defeat': {
        'panel': (378, 1135, 703, 1293),
        'centers': [93, 169, 253],
        'fps': 6.0, 'loop': False, 'title_rects': [(0, 0, 90, 22)],
    },
    'fatality': {
        'panel': (706, 1135, 1168, 1293),
        'centers': [92, 223, 314, 408],
        'fps': 8.0, 'loop': False, 'title_rects': [(0, 0, 100, 22)],
        'overlap': 24,
    },
    'taunts': {
        'panel': (16, 325, 294, 504),
        'centers': [45, 139, 224],
        'fps': 5.0, 'loop': True, 'title_rects': [(0, 0, 90, 22)],
    },
}


def fill_holes(mask: np.ndarray) -> np.ndarray:
    inv = (1 - mask).astype(np.uint8)
    ff = inv.copy()
    flood = np.zeros((mask.shape[0] + 2, mask.shape[1] + 2), np.uint8)
    cv2.floodFill(ff, flood, (0, 0), 2)
    out = mask.copy()
    out[ff == 1] = 1
    return out


def bbox_distance(a: Tuple[int, int, int, int], b: Tuple[int, int, int, int]) -> float:
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    dx = max(bx - (ax + aw), ax - (bx + bw), 0)
    dy = max(by - (ay + ah), ay - (by + bh), 0)
    return math.hypot(dx, dy)


def segment_frame(rgb: np.ndarray, expected_x: float, base_l: int, base_r: int) -> np.ndarray:
    h, w = rgb.shape[:2]
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    _, s, v = cv2.split(hsv)

    seed = (((s > 35) & (v > 28)) | (v > 78)).astype(np.uint8)
    seed[:3, :] = 0
    seed[-3:, :] = 0
    seed[:, :3] = 0
    seed[:, -3:] = 0

    # Discard tiny isolated background flecks before GrabCut.
    n, labels, stats, _ = cv2.connectedComponentsWithStats(seed, 8)
    clean_seed = np.zeros_like(seed)
    for i in range(1, n):
        if stats[i, cv2.CC_STAT_AREA] >= 4:
            clean_seed[labels == i] = 1
    seed = clean_seed

    probable_fg = cv2.dilate(
        seed,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (21, 21)),
        iterations=1,
    ) > 0

    gc_mask = np.full((h, w), cv2.GC_BGD, np.uint8)
    gc_mask[probable_fg] = cv2.GC_PR_FGD
    gc_mask[seed > 0] = cv2.GC_FGD
    gc_mask[:3, :] = cv2.GC_BGD
    gc_mask[-3:, :] = cv2.GC_BGD
    gc_mask[:, :3] = cv2.GC_BGD
    gc_mask[:, -3:] = cv2.GC_BGD

    bg_model = np.zeros((1, 65), np.float64)
    fg_model = np.zeros((1, 65), np.float64)
    try:
        cv2.grabCut(rgb, gc_mask, None, bg_model, fg_model, 2, cv2.GC_INIT_WITH_MASK)
        raw = ((gc_mask == cv2.GC_FGD) | (gc_mask == cv2.GC_PR_FGD)).astype(np.uint8)
    except cv2.error:
        raw = probable_fg.astype(np.uint8)

    raw = cv2.morphologyEx(
        raw,
        cv2.MORPH_CLOSE,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3)),
    )
    raw = fill_holes(raw)

    n, labels, stats, cents = cv2.connectedComponentsWithStats(raw, 8)
    comps = []
    for i in range(1, n):
        x, y, cw, ch, area = [int(z) for z in stats[i]]
        if area < 3:
            continue
        comp = labels == i
        max_v = int(v[comp].max()) if np.any(comp) else 0
        comps.append({
            'id': i, 'bbox': (x, y, cw, ch), 'area': area,
            'cx': float(cents[i][0]), 'cy': float(cents[i][1]), 'max_v': max_v,
        })

    # Main body/object components should be centered in the frame's base cell.
    main = [
        c for c in comps
        if c['area'] >= 70 and c['bbox'][3] >= 15 and (base_l - 2) <= c['cx'] <= (base_r + 2)
    ]
    if not main and comps:
        main = [min(comps, key=lambda c: abs(c['cx'] - expected_x) + (0 if c['area'] > 50 else 100))]

    selected_ids = {c['id'] for c in main}
    selected_boxes = [c['bbox'] for c in main]

    # Add separated feet, gloves, blood, and impact sparks near the selected action.
    changed = True
    while changed:
        changed = False
        for c in comps:
            if c['id'] in selected_ids:
                continue
            in_base = (base_l - 5) <= c['cx'] <= (base_r + 5)
            near = any(bbox_distance(c['bbox'], b) <= 28 for b in selected_boxes)
            effect = c['max_v'] >= 115 and any(bbox_distance(c['bbox'], b) <= 42 for b in selected_boxes)
            small_piece = c['area'] <= 220 and near
            if (in_base and (c['area'] >= 8 or c['max_v'] >= 100)) or effect or small_piece:
                selected_ids.add(c['id'])
                selected_boxes.append(c['bbox'])
                changed = True

    out = np.zeros_like(raw)
    for comp_id in selected_ids:
        out[labels == comp_id] = 1

    # Keep a controlled overlap so punches/kicks are not clipped, but remove adjacent poses.
    clip_l = max(0, base_l - 15)
    clip_r = min(w, base_r + 15)
    out[:, :clip_l] = 0
    out[:, clip_r:] = 0

    # Restore one pixel of dark outline and remove dim detached shadows.
    out = cv2.dilate(out, np.ones((2, 2), np.uint8), iterations=1)
    n, labels, stats, _ = cv2.connectedComponentsWithStats(out, 8)
    cleaned = np.zeros_like(out)
    for i in range(1, n):
        comp = labels == i
        area = int(stats[i, cv2.CC_STAT_AREA])
        max_v = int(v[comp].max()) if np.any(comp) else 0
        if area >= 10 or max_v >= 125:
            cleaned[comp] = 1
    return cleaned



def select_from_panel_mask(panel_mask: np.ndarray, panel_rgb: np.ndarray, crop_left: int, crop_right: int, center: int, base_left: int, base_right: int) -> np.ndarray:
    raw = panel_mask[:, crop_left:crop_right].copy()
    rgb = panel_rgb[:, crop_left:crop_right]
    h, w = raw.shape
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    _, _, v = cv2.split(hsv)
    expected_x = center - crop_left
    base_l = base_left - crop_left
    base_r = base_right - crop_left

    n, labels, stats, cents = cv2.connectedComponentsWithStats(raw, 8)
    comps = []
    for i in range(1, n):
        x, y, cw, ch, area = [int(z) for z in stats[i]]
        if area < 3:
            continue
        comp = labels == i
        max_v = int(v[comp].max()) if np.any(comp) else 0
        comps.append({
            'id': i, 'bbox': (x, y, cw, ch), 'area': area,
            'cx': float(cents[i][0]), 'cy': float(cents[i][1]), 'max_v': max_v,
        })

    main = [
        c for c in comps
        if c['area'] >= 60 and c['bbox'][3] >= 12 and (base_l - 3) <= c['cx'] <= (base_r + 3)
    ]
    if not main and comps:
        main = [min(comps, key=lambda c: abs(c['cx'] - expected_x) + (0 if c['area'] > 40 else 100))]

    selected_ids = {c['id'] for c in main}
    selected_boxes = [c['bbox'] for c in main]
    changed = True
    while changed:
        changed = False
        for c in comps:
            if c['id'] in selected_ids:
                continue
            in_base = (base_l - 6) <= c['cx'] <= (base_r + 6)
            near = any(bbox_distance(c['bbox'], b) <= 28 for b in selected_boxes)
            effect = c['max_v'] >= 115 and any(bbox_distance(c['bbox'], b) <= 44 for b in selected_boxes)
            small_piece = c['area'] <= 220 and near
            if (in_base and (c['area'] >= 8 or c['max_v'] >= 100)) or effect or small_piece:
                selected_ids.add(c['id'])
                selected_boxes.append(c['bbox'])
                changed = True

    out = np.zeros_like(raw)
    for comp_id in selected_ids:
        out[labels == comp_id] = 1

    clip_l = max(0, base_l - 15)
    clip_r = min(w, base_r + 15)
    out[:, :clip_l] = 0
    out[:, clip_r:] = 0

    n, labels, stats, _ = cv2.connectedComponentsWithStats(out, 8)
    cleaned = np.zeros_like(out)
    for i in range(1, n):
        comp = labels == i
        area = int(stats[i, cv2.CC_STAT_AREA])
        max_v = int(v[comp].max()) if np.any(comp) else 0
        if area >= 10 or max_v >= 125:
            cleaned[comp] = 1
    return cleaned

def make_boundaries(centers: List[int], panel_w: int) -> List[Tuple[int, int]]:
    bounds = []
    for i, c in enumerate(centers):
        left = 0 if i == 0 else int(round((centers[i - 1] + c) / 2))
        right = panel_w if i == len(centers) - 1 else int(round((c + centers[i + 1]) / 2))
        bounds.append((left, right))
    return bounds


def checker_preview(rgba: Image.Image, scale: int = 1) -> Image.Image:
    arr = np.array(rgba)
    h, w = arr.shape[:2]
    yy, xx = np.indices((h, w))
    patt = ((xx // 8 + yy // 8) % 2).astype(np.uint8)
    bg = np.where(patt[..., None] == 0, 215, 165).astype(np.uint8)
    bg = np.repeat(bg, 3, axis=2)
    a = arr[..., 3:4].astype(np.float32) / 255.0
    comp = (arr[..., :3] * a + bg * (1 - a)).astype(np.uint8)
    im = Image.fromarray(comp, 'RGB')
    if scale != 1:
        im = im.resize((w * scale, h * scale), Image.Resampling.NEAREST)
    return im


def build() -> None:
    if OUT_ROOT.exists():
        shutil.rmtree(OUT_ROOT)
    if ZIP_PATH.exists():
        ZIP_PATH.unlink()

    for sub in ['sprites', 'atlas', 'godot', 'data', 'source', 'preview', 'tools']:
        (OUT_ROOT / sub).mkdir(parents=True, exist_ok=True)

    source_im = Image.open(SOURCE).convert('RGB')
    source_np = np.array(source_im)
    shutil.copy2(SOURCE, OUT_ROOT / 'source' / 'original_sprite_sheet.png')

    manifest = {
        'character': 'Clay',
        'canvas_size': [CANVAS_W, CANVAS_H],
        'anchor': [ANCHOR_X, BASELINE_Y],
        'coordinate_note': 'Frames share a 256x192 canvas. Character center is x=128 and the ground baseline is y=176.',
        'animations': {},
    }
    all_frames: List[Tuple[str, int, Image.Image, Path]] = []

    for anim_name, cfg in ANIMS.items():
        x0, y0, x1, y1 = cfg['panel']
        panel = source_np[y0:y1, x0:x1].copy()
        ph, pw = panel.shape[:2]

        # Neutralize labels and panel borders before extraction.
        bg_sample = panel[max(0, ph - 20):ph - 3, max(0, pw - 60):pw - 3]
        bg_color = np.median(bg_sample.reshape(-1, 3), axis=0).astype(np.uint8) if bg_sample.size else np.array([8, 9, 9], np.uint8)
        for rx0, ry0, rx1, ry1 in cfg.get('title_rects', []):
            panel[max(0, ry0):min(ph, ry1), max(0, rx0):min(pw, rx1)] = bg_color
        panel[:2, :] = bg_color
        panel[-2:, :] = bg_color
        panel[:, :2] = bg_color
        panel[:, -2:] = bg_color

        centers = cfg['centers']
        boundaries = make_boundaries(centers, pw)
        anim_dir = OUT_ROOT / 'sprites' / anim_name
        anim_dir.mkdir(parents=True, exist_ok=True)
        frame_files = []
        overlap = int(cfg.get('overlap', 18))

        # Run the expensive foreground extraction once per animation panel, then split it.
        panel_fg = segment_frame(panel, pw / 2.0, 0, pw)

        for idx, (center, (base_left, base_right)) in enumerate(zip(centers, boundaries)):
            crop_left = max(0, base_left - overlap)
            crop_right = min(pw, base_right + overlap)
            crop_rgb = panel[:, crop_left:crop_right].copy()
            expected_x = center - crop_left
            base_l_crop = base_left - crop_left
            base_r_crop = base_right - crop_left

            mask = select_from_panel_mask(panel_fg, panel, crop_left, crop_right, center, base_left, base_right)
            rgba = np.dstack([crop_rgb, mask * 255]).astype(np.uint8)

            canvas = np.zeros((CANVAS_H, CANVAS_W, 4), np.uint8)
            dest_x = int(round(ANCHOR_X - expected_x))
            dest_y = int(round(BASELINE_Y - (ph - 1)))

            # Safe clipped paste into fixed canvas.
            src_l = max(0, -dest_x)
            src_t = max(0, -dest_y)
            dst_l = max(0, dest_x)
            dst_t = max(0, dest_y)
            copy_w = min(rgba.shape[1] - src_l, CANVAS_W - dst_l)
            copy_h = min(rgba.shape[0] - src_t, CANVAS_H - dst_t)
            if copy_w > 0 and copy_h > 0:
                canvas[dst_t:dst_t + copy_h, dst_l:dst_l + copy_w] = rgba[src_t:src_t + copy_h, src_l:src_l + copy_w]

            frame_img = Image.fromarray(canvas, 'RGBA')
            filename = f'{anim_name}_{idx:02d}.png'
            frame_path = anim_dir / filename
            frame_img.save(frame_path, optimize=True, compress_level=9)
            frame_files.append(f'sprites/{anim_name}/{filename}')
            all_frames.append((anim_name, idx, frame_img, frame_path))

        manifest['animations'][anim_name] = {
            'fps': cfg['fps'],
            'loop': cfg['loop'],
            'frame_count': len(frame_files),
            'frames': frame_files,
        }

    # Build a single power-of-grid atlas for Godot runtime use.
    atlas_rows = math.ceil(len(all_frames) / ATLAS_COLS)
    atlas = Image.new('RGBA', (ATLAS_COLS * CANVAS_W, atlas_rows * CANVAS_H), (0, 0, 0, 0))
    atlas_entries = []
    for atlas_i, (anim_name, frame_idx, frame_img, frame_path) in enumerate(all_frames):
        col = atlas_i % ATLAS_COLS
        row = atlas_i // ATLAS_COLS
        x = col * CANVAS_W
        y = row * CANVAS_H
        atlas.paste(frame_img, (x, y))
        atlas_entries.append({
            'animation': anim_name,
            'frame': frame_idx,
            'region': [x, y, CANVAS_W, CANVAS_H],
            'individual_file': str(frame_path.relative_to(OUT_ROOT)).replace('\\', '/'),
        })
    atlas_path = OUT_ROOT / 'atlas' / 'clay_atlas.png'
    atlas.save(atlas_path, optimize=True, compress_level=9)
    (OUT_ROOT / 'atlas' / 'clay_atlas.json').write_text(json.dumps({
        'image': 'clay_atlas.png',
        'size': list(atlas.size),
        'cell_size': [CANVAS_W, CANVAS_H],
        'columns': ATLAS_COLS,
        'frames': atlas_entries,
    }, indent=2), encoding='utf-8')

    (OUT_ROOT / 'data' / 'animations.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')

    # Godot 4 SpriteFrames resource using AtlasTexture regions.
    tres_lines = [
        f'[gd_resource type="SpriteFrames" load_steps={len(all_frames) + 2} format=3]',
        '',
        '[ext_resource type="Texture2D" path="res://clay_character/atlas/clay_atlas.png" id="1_atlas"]',
        '',
    ]
    sub_ids = {}
    for atlas_i, entry in enumerate(atlas_entries):
        anim = entry['animation']
        fi = entry['frame']
        sub_id = f'AtlasTexture_{anim}_{fi:02d}'
        sub_ids[(anim, fi)] = sub_id
        x, y, w, h = entry['region']
        tres_lines += [
            f'[sub_resource type="AtlasTexture" id="{sub_id}"]',
            'atlas = ExtResource("1_atlas")',
            f'region = Rect2({x}, {y}, {w}, {h})',
            '',
        ]
    anim_blocks = []
    for anim_name, data in manifest['animations'].items():
        frame_dicts = []
        for i in range(data['frame_count']):
            frame_dicts.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sub_ids[(anim_name, i)])
        block = '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}' % (
            ', '.join(frame_dicts),
            'true' if data['loop'] else 'false',
            anim_name,
            data['fps'],
        )
        anim_blocks.append(block)
    tres_lines += ['[resource]', 'animations = [%s]' % ', '.join(anim_blocks), '']
    (OUT_ROOT / 'godot' / 'clay_sprite_frames.tres').write_text('\n'.join(tres_lines), encoding='utf-8')

    (OUT_ROOT / 'godot' / 'clay_character.gd').write_text('''extends AnimatedSprite2D

const CLAY_FRAMES: SpriteFrames = preload("res://clay_character/godot/clay_sprite_frames.tres")

func _ready() -> void:
    sprite_frames = CLAY_FRAMES
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    centered = true
    if animation == &"":
        animation = &"idle"
    play()

func play_action(action_name: StringName, restart: bool = true) -> void:
    if not sprite_frames.has_animation(action_name):
        push_warning("Unknown Clay animation: %s" % action_name)
        return
    if restart:
        play(action_name)
    else:
        animation = action_name
        play()
''', encoding='utf-8')

    (OUT_ROOT / 'godot' / 'ClayCharacter.tscn').write_text('''[gd_scene load_steps=3 format=3]

[ext_resource type="SpriteFrames" path="res://clay_character/godot/clay_sprite_frames.tres" id="1_frames"]
[ext_resource type="Script" path="res://clay_character/godot/clay_character.gd" id="2_script"]

[node name="ClayCharacter" type="AnimatedSprite2D"]
sprite_frames = ExtResource("1_frames")
animation = &"idle"
autoplay = "idle"
centered = true
texture_filter = 1
script = ExtResource("2_script")
''', encoding='utf-8')

    # Contact-sheet preview of all extracted transparent frames.
    label_w = 170
    preview_scale = 1
    row_h = CANVAS_H + 28
    max_frames = max(d['frame_count'] for d in manifest['animations'].values())
    preview_w = label_w + max_frames * CANVAS_W
    preview_h = len(manifest['animations']) * row_h
    preview = Image.new('RGB', (preview_w, preview_h), 'white')
    draw = ImageDraw.Draw(preview)
    font = ImageFont.load_default()
    frame_lookup = {(a, i): im for a, i, im, _ in all_frames}
    for row, (anim_name, data) in enumerate(manifest['animations'].items()):
        y = row * row_h
        draw.rectangle((0, y, preview_w, y + row_h - 1), outline=(100, 100, 100))
        draw.text((8, y + 8), f"{anim_name} ({data['frame_count']})", fill=(0, 0, 0), font=font)
        for i in range(data['frame_count']):
            tile = checker_preview(frame_lookup[(anim_name, i)], scale=preview_scale)
            preview.paste(tile, (label_w + i * CANVAS_W, y + 24))
            draw.text((label_w + i * CANVAS_W + 4, y + 6), f'{i:02d}', fill=(0, 0, 0), font=font)
    preview.save(OUT_ROOT / 'preview' / 'extracted_contact_sheet.png', optimize=True, compress_level=9)

    # Rebuild tool for users who want to tweak coordinates/segmentation.
    shutil.copy2(Path(__file__), OUT_ROOT / 'tools' / 'rebuild_from_source.py')

    readme = f'''# Clay — Godot 4 sprite pack

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

Every individual frame is **{CANVAS_W}×{CANVAS_H} px** with a shared character anchor at **x={ANCHOR_X}** and ground baseline at **y={BASELINE_Y}**. This prevents the usual frame-to-frame jitter caused by individually trimmed sprites.

## Animation names

`{', '.join(manifest['animations'].keys())}`

## Godot import recommendations

Select `atlas/clay_atlas.png` in Godot's FileSystem panel and use:

- Filter: Off
- Mipmaps: Off
- Compression mode: Lossless
- Repeat: Disabled

Then click **Reimport**. The included scene also requests nearest-neighbour filtering at runtime.

## Notes

The source is an AI-generated presentation sheet rather than a purpose-built production sprite sheet. The extractor removes the dark panel background and separates the visible poses, but a few complex multi-character/effect frames may still benefit from manual pixel cleanup before final release.
'''
    (OUT_ROOT / 'README.md').write_text(readme, encoding='utf-8')

    with zipfile.ZipFile(ZIP_PATH, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for path in sorted(OUT_ROOT.rglob('*')):
            if path.is_file():
                zf.write(path, path.relative_to(OUT_ROOT.parent))

    print(json.dumps({
        'zip': str(ZIP_PATH),
        'folder': str(OUT_ROOT),
        'animations': len(manifest['animations']),
        'frames': len(all_frames),
        'atlas_size': list(atlas.size),
    }, indent=2))


if __name__ == '__main__':
    build()
