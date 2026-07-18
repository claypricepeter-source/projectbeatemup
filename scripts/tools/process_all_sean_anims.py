import os
from PIL import Image
import numpy as np

# Mappings of animation sheets to process with their exact rows and columns
SHEETS = {
    "walk": {
        "path": r"C:\Users\clayp\.gemini\antigravity\brain\fb5ee920-b9e7-4306-bfb0-6dac60931269\sean_walk_sheet_1784344435656.jpg",
        "rows": [
            {"y_min": 78, "y_max": 502, "cols": 3},
            {"y_min": 568, "y_max": 1014, "cols": 3}
        ]
    },
    "jump": {
        "path": r"C:\Users\clayp\.gemini\antigravity\brain\fb5ee920-b9e7-4306-bfb0-6dac60931269\sean_jump_sheet_1784344444804.jpg",
        "rows": [
            {"y_min": 184, "y_max": 779, "cols": 4}
        ]
    },
    "hurt": {
        "path": r"C:\Users\clayp\.gemini\antigravity\brain\fb5ee920-b9e7-4306-bfb0-6dac60931269\sean_hurt_sheet_1784344454762.jpg",
        "rows": [
            {"y_min": 230, "y_max": 789, "cols": 3}
        ]
    },
    "knockdown": {
        "path": r"C:\Users\clayp\.gemini\antigravity\brain\fb5ee920-b9e7-4306-bfb0-6dac60931269\sean_knockdown_sheet_1784344464010.jpg",
        "rows": [
            {"y_min": 125, "y_max": 492, "cols": 3},
            {"y_min": 696, "y_max": 940, "cols": 3}
        ]
    },
    "victory": {
        "path": r"C:\Users\clayp\.gemini\antigravity\brain\fb5ee920-b9e7-4306-bfb0-6dac60931269\sean_victory_sheet_1784344473500.jpg",
        "rows": [
            {"y_min": 286, "y_max": 768, "cols": 4}
        ]
    },
    "death": {
        "path": r"C:\Users\clayp\.gemini\antigravity\brain\fb5ee920-b9e7-4306-bfb0-6dac60931269\sean_death_sheet_1784344482966.jpg",
        "rows": [
            {"y_min": 378, "y_max": 600, "cols": 2},
            {"y_min": 632, "y_max": 655, "cols": 4}
        ]
    }
}

base_out_dir = r"d:\DIXON\projectbeatemup\assets\sprites\player\sean_smooth"

CANVAS_SIZE = (256, 192)
FEET_Y = 176
TARGET_HEIGHT = 148
TARGET_WIDTH = 224

for anim, config in SHEETS.items():
    img_path = config["path"]
    rows = config["rows"]
    
    out_dir = os.path.join(base_out_dir, anim)
    os.makedirs(out_dir, exist_ok=True)
    
    # Load and do dynamic background keying using int32 to prevent unsigned underflow
    im = Image.open(img_path)
    arr = np.array(im, dtype=np.int32)
    bg_color = arr[0, 0, :3]
    
    dist = np.abs(arr[:, :, :3] - bg_color).sum(axis=2)
    
    # Create RGBA array with transparent background
    rgba_arr = np.array(im.convert("RGBA"))
    bg_mask = dist <= 45
    rgba_arr[bg_mask, 3] = 0
    transparent_im = Image.fromarray(rgba_arr, "RGBA")
    
    width, height = im.size
    frame_index = 1
    
    for row in rows:
        y_min = row["y_min"]
        y_max = row["y_max"]
        cols = row["cols"]
        col_w = width // cols
        
        for c in range(cols):
            x_min = c * col_w
            x_max = (c + 1) * col_w if c < cols - 1 else width
            
            # Crop the cell
            cell = transparent_im.crop((x_min, y_min, x_max, y_max))
            
            # Find the tight bounding box of the non-transparent pixels
            bounds = cell.getchannel("A").getbbox()
            if bounds is None:
                print(f"Warning: {anim} frame {frame_index} is empty!")
                sprite = cell
            else:
                sprite = cell.crop(bounds)
                
            scale = min(
                TARGET_HEIGHT / float(sprite.height),
                TARGET_WIDTH / float(sprite.width)
            )
            # Cap scale to prevent blowing up tiny sprites (like lying flat)
            if scale > 2.0:
                scale = 2.0
                
            size = (
                max(1, round(sprite.width * scale)),
                max(1, round(sprite.height * scale))
            )
            sprite = sprite.resize(size, Image.Resampling.NEAREST)
            
            # Position on canvas. Feet Y anchor is FEET_Y.
            # For lying flat / falling sprites, placing the bottom of their bounds at FEET_Y
            # ensures they lie flat on the ground plane, not float.
            canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
            position = ((CANVAS_SIZE[0] - size[0]) // 2, FEET_Y - size[1])
            canvas.alpha_composite(sprite, position)
            
            save_path = os.path.join(out_dir, f"{anim}{frame_index}.png")
            canvas.save(save_path)
            print(f"Saved: {save_path} (original tight size: {sprite.size})")
            frame_index += 1

print("Processing complete!")
