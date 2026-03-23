"""Generate CiteCoach app icon - dark theme with emerald speech bubble + eye."""
from PIL import Image, ImageDraw
import math
import os

def create_icon(size):
    """Create a CiteCoach icon at the given size."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background - dark zinc with slight rounded corners feel
    # Use the app's zinc-950 background: #09090B
    bg_color = (9, 9, 11)
    draw.rounded_rectangle(
        [0, 0, size - 1, size - 1],
        radius=int(size * 0.22),
        fill=bg_color,
    )

    # Draw speech bubble shape (represents communication/citation)
    # Emerald accent: #10B981
    emerald = (16, 185, 129)
    # Cyan accent: #06B6D4
    cyan = (6, 182, 212)

    center_x = size * 0.48
    center_y = size * 0.42
    bubble_w = size * 0.58
    bubble_h = size * 0.46

    # Main bubble body (rounded rectangle)
    bx1 = center_x - bubble_w / 2
    by1 = center_y - bubble_h / 2
    bx2 = center_x + bubble_w / 2
    by2 = center_y + bubble_h / 2
    bubble_radius = int(size * 0.10)

    draw.rounded_rectangle(
        [bx1, by1, bx2, by2],
        radius=bubble_radius,
        fill=emerald,
    )

    # Bubble tail (triangle pointing bottom-left)
    tail_points = [
        (center_x - bubble_w * 0.15, by2 - size * 0.02),
        (center_x - bubble_w * 0.42, by2 + size * 0.14),
        (center_x + bubble_w * 0.05, by2 - size * 0.02),
    ]
    draw.polygon(tail_points, fill=emerald)

    # "Eye" accent - represents AI watching/verifying (small cyan circle)
    eye_cx = center_x + bubble_w * 0.12
    eye_cy = center_y - bubble_h * 0.02
    eye_r = size * 0.065

    # Eye outer (darker bg)
    draw.ellipse(
        [eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r],
        fill=bg_color,
    )
    # Eye inner (cyan dot)
    inner_r = eye_r * 0.55
    draw.ellipse(
        [eye_cx - inner_r, eye_cy - inner_r, eye_cx + inner_r, eye_cy + inner_r],
        fill=cyan,
    )

    # "C" letter cutout in the bubble (represents CiteCoach)
    c_cx = center_x - bubble_w * 0.10
    c_cy = center_y
    c_r = size * 0.11
    c_thickness = size * 0.035

    # Draw C as arc using thick outline
    c_outer = c_r
    c_inner = c_r - c_thickness

    # C shape - draw as a thick arc
    # Draw full circle in bg_color, then cover part to make C
    for angle_deg in range(-45, 225):
        angle = math.radians(angle_deg)
        for r in [c_inner + t * (c_outer - c_inner) / 8 for t in range(9)]:
            x = int(c_cx + r * math.cos(angle))
            y = int(c_cy + r * math.sin(angle))
            if 0 <= x < size and 0 <= y < size:
                draw.point((x, y), fill=bg_color)

    return img


def save_ios_icons(base_icon):
    """Save all required iOS icon sizes."""
    icon_dir = '/home/user/CiteCoach/ios/Runner/Assets.xcassets/AppIcon.appiconset'

    sizes = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }

    for filename, target_size in sizes.items():
        resized = base_icon.resize((target_size, target_size), Image.LANCZOS)
        # iOS icons must not have alpha channel
        rgb_icon = Image.new('RGB', (target_size, target_size), (9, 9, 11))
        rgb_icon.paste(resized, mask=resized.split()[3] if resized.mode == 'RGBA' else None)
        rgb_icon.save(os.path.join(icon_dir, filename), 'PNG')
        print(f'  iOS: {filename} ({target_size}x{target_size})')


def save_android_icons(base_icon):
    """Save all required Android icon sizes."""
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    base_dir = '/home/user/CiteCoach/android/app/src/main/res'
    for folder, target_size in android_sizes.items():
        resized = base_icon.resize((target_size, target_size), Image.LANCZOS)
        rgb_icon = Image.new('RGB', (target_size, target_size), (9, 9, 11))
        rgb_icon.paste(resized, mask=resized.split()[3] if resized.mode == 'RGBA' else None)
        path = os.path.join(base_dir, folder, 'ic_launcher.png')
        rgb_icon.save(path, 'PNG')
        print(f'  Android: {folder}/ic_launcher.png ({target_size}x{target_size})')


if __name__ == '__main__':
    print('Generating CiteCoach app icon...')
    icon = create_icon(1024)

    print('Saving iOS icons...')
    save_ios_icons(icon)

    print('Saving Android icons...')
    save_android_icons(icon)

    # Also save the base icon to assets
    assets_dir = '/home/user/CiteCoach/assets/icons'
    os.makedirs(assets_dir, exist_ok=True)
    icon.save(os.path.join(assets_dir, 'app_icon.png'), 'PNG')
    print(f'  Base icon saved to assets/icons/app_icon.png')

    print('Done!')
