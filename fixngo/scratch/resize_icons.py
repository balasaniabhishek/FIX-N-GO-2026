"""
Script to resize provided icon images and copy them to all required Flutter icon locations.
Run after manually placing:
  - tech_icon_source.png (FixTech - technician icon)
  - customer_icon_source.png (Fix-N-Go - customer icon)
in C:/Users/MRCE DIGITAL.LIB/Desktop/Fix-N-Go/FIX-N-GO-2026/fixngo/scratch/
"""
from PIL import Image
import os, shutil

BASE = r"C:\Users\MRCE DIGITAL.LIB\Desktop\Fix-N-Go\FIX-N-GO-2026\fixngo"
SCRATCH = os.path.join(BASE, "scratch")

TECH_SRC   = os.path.join(SCRATCH, "tech_icon_source.png")
CUST_SRC   = os.path.join(SCRATCH, "customer_icon_source.png")

TECH_APP   = os.path.join(BASE, "apps", "technician_app")
CUST_APP   = os.path.join(BASE, "apps", "customer_app")

def resize_and_save(src_path, dest_path, size):
    img = Image.open(src_path).convert("RGBA")
    img = img.resize((size, size), Image.LANCZOS)
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    img.save(dest_path, "PNG")
    print(f"  Saved {size}x{size} -> {dest_path}")

def apply_icons(src, app_dir, label):
    print(f"\nProcessing {label} icons...")

    # Web icons
    resize_and_save(src, os.path.join(app_dir, "web", "favicon.png"), 32)
    resize_and_save(src, os.path.join(app_dir, "web", "icons", "Icon-192.png"), 192)
    resize_and_save(src, os.path.join(app_dir, "web", "icons", "Icon-512.png"), 512)
    resize_and_save(src, os.path.join(app_dir, "web", "icons", "Icon-maskable-192.png"), 192)
    resize_and_save(src, os.path.join(app_dir, "web", "icons", "Icon-maskable-512.png"), 512)

    # Android mipmap icons
    android_sizes = {
        "mipmap-mdpi":    48,
        "mipmap-hdpi":    72,
        "mipmap-xhdpi":   96,
        "mipmap-xxhdpi":  144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        dest = os.path.join(app_dir, "android", "app", "src", "main", "res", folder, "ic_launcher.png")
        resize_and_save(src, dest, size)
        # Also round version
        dest_round = dest.replace("ic_launcher.png", "ic_launcher_round.png")
        resize_and_save(src, dest_round, size)

    # iOS icons (common sizes)
    ios_sizes = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
    ios_dir = os.path.join(app_dir, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    for size in ios_sizes:
        dest = os.path.join(ios_dir, f"Icon-App-{size}x{size}@1x.png")
        resize_and_save(src, dest, size)

    print(f"DONE: All {label} icons updated!")

if __name__ == "__main__":
    if not os.path.exists(TECH_SRC):
        print(f"ERROR: Technician source icon not found at: {TECH_SRC}")
    else:
        apply_icons(TECH_SRC, TECH_APP, "Technician App (FixTech)")

    if not os.path.exists(CUST_SRC):
        print(f"ERROR: Customer source icon not found at: {CUST_SRC}")
    else:
        apply_icons(CUST_SRC, CUST_APP, "Customer App (Fix-N-Go)")
