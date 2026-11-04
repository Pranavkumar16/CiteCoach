"""Render CiteCoach's vector-style glass book mark and native launcher assets.

Keep the foreground inside Android's adaptive-icon safe circle. The mark uses
large solid shapes so it stays recognisable at small launcher sizes.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json

INK = (39, 27, 33, 255)
PAPER = (241, 233, 216, 255)
SIGNAL = (217, 239, 87, 255)


def make_icon(size, foreground=False):
    # Draw at 2x resolution for clean edges after downsampling.
    side = 2048
    im = Image.new('RGBA', (side, side), (0, 0, 0, 0) if foreground else INK)
    def rect(values):
        return tuple(round(v * 2) for v in values)
    def pts(values):
        return [(round(x * 2), round(y * 2)) for x, y in values]
    if not foreground:
        glow = Image.new('RGBA', im.size)
        d = ImageDraw.Draw(glow)
        d.ellipse(rect((-160, -240, 650, 570)), fill=(125, 145, 49, 110))
        d.ellipse(rect((580, 460, 1210, 1160)), fill=(170, 70, 68, 90))
        im = Image.alpha_composite(im, glow.filter(ImageFilter.GaussianBlur(160)))
        d = ImageDraw.Draw(im)
        d.rounded_rectangle(rect((43, 43, 981, 981)), radius=200, outline=(241, 233, 216, 32), width=3)
    d = ImageDraw.Draw(im)
    # Broad open pages, with a single fold and no lettering or tiny sparkles.
    left = [(263, 325), (346, 306), (423, 319), (495, 363), (495, 702), (420, 662), (344, 647), (263, 660)]
    right = [(526, 363), (599, 319), (676, 306), (759, 325), (759, 660), (678, 647), (603, 662), (526, 702)]
    d.polygon(pts(left), fill=PAPER)
    d.polygon(pts(right), fill=(222, 216, 198, 255))
    d.line(pts([(287, 351), (347, 336), (408, 346), (466, 380)]), fill=(255, 255, 255, 255), width=8, joint='curve')
    d.line(pts([(552, 380), (609, 346), (675, 336), (733, 351)]), fill=(255, 255, 255, 190), width=8, joint='curve')
    d.line(pts([(315, 431), (373, 432), (437, 457)]), fill=(117, 108, 101, 255), width=14, joint='curve')
    d.line(pts([(315, 493), (370, 493), (437, 519)]), fill=(117, 108, 101, 255), width=14, joint='curve')
    # One distinct proof badge, legible without the surrounding artwork.
    d.ellipse(rect((581, 541, 769, 729)), fill=INK)
    d.ellipse(rect((593, 553, 757, 717)), fill=SIGNAL)
    d.line(pts([(630, 634), (662, 666), (717, 606)]), fill=INK, width=25, joint='curve')
    return im.resize((size, size), Image.Resampling.LANCZOS)


def main():
    root = Path('assets/icons')
    root.mkdir(parents=True, exist_ok=True)
    icon = make_icon(1024)
    foreground = make_icon(1024, True)
    icon.convert('RGB').save(root / 'app_icon.png')
    foreground.save(root / 'app_icon_foreground.png')
    # Commit previews/native assets too, so builds never show the previous C icon.
    res = Path('android/app/src/main/res')
    for density, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        dest = res / f'mipmap-{density}' / 'ic_launcher.png'
        dest.parent.mkdir(parents=True, exist_ok=True)
        icon.resize((px, px), Image.Resampling.LANCZOS).save(dest)
        dest = res / f'drawable-{density}' / 'ic_launcher_foreground.png'
        dest.parent.mkdir(parents=True, exist_ok=True)
        foreground.resize((round(px * 2.25), round(px * 2.25)), Image.Resampling.LANCZOS).save(dest)
    ios = Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
    contents = ios / 'Contents.json'
    if contents.exists():
        for item in json.loads(contents.read_text()).get('images', []):
            if item.get('filename'):
                px = round(float(item['size'].split('x')[0]) * float(item['scale'].rstrip('x')))
                icon.convert('RGB').resize((px, px), Image.Resampling.LANCZOS).save(ios / item['filename'])
    print('Generated CiteCoach frosted book and evidence launcher mark')

if __name__ == '__main__':
    main()
