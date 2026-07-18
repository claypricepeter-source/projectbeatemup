import os
import glob
from PIL import Image
import numpy as np

BASE_DIR = r"d:\DIXON\projectbeatemup\assets\sprites\bosses\magneto_boss_codex_assets\frames_uniform"

ANIMATIONS = {
    "idle_walk": {"loop": True},
    "light_attack_metal_swipe": {"loop": False},
    "heavy_attack_magnetic_crush": {"loop": False},
    "special_attack_rainbow_meteor": {"loop": False},
    "dash_run": {"loop": True},
    "damage_ko": {"loop": False},
}


def clean_existing_inbetweens(anim_dir):
    pattern = os.path.join(anim_dir, "*b.png")
    for f in glob.glob(pattern):
        os.remove(f)
        print(f"Deleted old in-between: {os.path.basename(f)}")


def interpolate_two_images(img1_path, img2_path, out_path):
    im1 = Image.open(img1_path).convert("RGBA")
    im2 = Image.open(img2_path).convert("RGBA")
    
    arr1 = np.array(im1, dtype=np.float32)
    arr2 = np.array(im2, dtype=np.float32)
    
    # 50% blend of both frames
    blend = 0.5 * arr1 + 0.5 * arr2
    
    # Threshold alpha channel to keep boundaries crisp
    alpha = blend[:, :, 3]
    binary_alpha = np.where(alpha > 127, 255, 0).astype(np.uint8)
    
    rgb = blend[:, :, :3]
    
    # Pixel art correction: if a pixel was opaque in only one frame,
    # pick the color directly from that frame to prevent color blending with transparent borders.
    a1 = arr1[:, :, 3]
    a2 = arr2[:, :, 3]
    
    use1 = (a1 > 0) & (a2 == 0)
    use2 = (a2 > 0) & (a1 == 0)
    both = (a1 > 0) & (a2 > 0)
    
    result_rgb = np.zeros_like(rgb, dtype=np.uint8)
    result_rgb[both] = (0.5 * arr1[both, :3] + 0.5 * arr2[both, :3]).astype(np.uint8)
    result_rgb[use1] = arr1[use1, :3].astype(np.uint8)
    result_rgb[use2] = arr2[use2, :3].astype(np.uint8)
    
    result_arr = np.zeros_like(arr1, dtype=np.uint8)
    result_arr[:, :, :3] = result_rgb
    result_arr[:, :, 3] = binary_alpha
    
    res_img = Image.fromarray(result_arr, "RGBA")
    res_img.save(out_path)


def main():
    for anim, config in ANIMATIONS.items():
        anim_dir = os.path.join(BASE_DIR, anim)
        if not os.path.exists(anim_dir):
            print(f"Skipping {anim}: directory not found")
            continue
            
        clean_existing_inbetweens(anim_dir)
        
        # Get all original frames (excluding generated b-frames)
        files = sorted([f for f in os.listdir(anim_dir) if f.endswith(".png") and not f.endswith("b.png")])
        print(f"Processing '{anim}' ({len(files)} original frames)...")
        
        num_frames = len(files)
        if num_frames < 2:
            print(f"Animation {anim} has less than 2 frames, cannot interpolate.")
            continue
            
        for i in range(num_frames):
            curr_file = files[i]
            curr_path = os.path.join(anim_dir, curr_file)
            
            # Decide next frame
            is_last = (i == num_frames - 1)
            if is_last:
                if config["loop"]:
                    next_file = files[0]
                else:
                    # Non-looping animation: do not interpolate after the last frame
                    continue
            else:
                next_file = files[i + 1]
                
            next_path = os.path.join(anim_dir, next_file)
            
            # Determine output filename (e.g. idle_walk_000.png -> idle_walk_000b.png)
            base_name = os.path.splitext(curr_file)[0]
            out_file = f"{base_name}b.png"
            out_path = os.path.join(anim_dir, out_file)
            
            interpolate_two_images(curr_path, next_path, out_path)
            print(f"  Generated in-between: {out_file} from {curr_file} and {next_file}")
            
    print("All animations processed successfully!")


if __name__ == "__main__":
    main()
