"""Generate CiteCoach launcher artwork for Android and iOS during CI."""
from pathlib import Path
from PIL import Image, ImageDraw
import math

def make_icon(size, foreground=False):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0) if foreground else (11, 18, 56, 255))
    d = ImageDraw.Draw(im)
    s = size / 1024
    def xy(points):
        return [(round(x*s), round(y*s)) for x, y in points]
    def line(points, fill, width):
        d.line(xy(points), fill=fill, width=round(width*s), joint="curve")
    if not foreground:
        for y in range(size):
            t = y / max(1, size - 1)
            d.line([(0,y),(size,y)], fill=(int(9+42*t),int(19+6*t),int(77+50*t),255))
    white=(248,249,255,255)
    line([(145,300),(145,690),(340,690),(500,758),(500,348),(343,281),(145,300)],white,34)
    line([(500,348),(650,285),(835,300),(835,690),(650,690),(500,758)],white,34)
    line([(200,350),(330,340),(442,385)],(179,185,255,255),18)
    line([(560,385),(674,340),(780,350)],(179,185,255,255),18)
    d.ellipse(tuple(round(v*s) for v in (560,365,812,617)),outline=white,width=round(40*s))
    line([(763,579),(880,700)],white,45)
    line([(625,491),(676,540),(758,448)],(51,226,239,255),34)
    for x,y,r in [(325,195,17),(410,245,12),(500,150,11)]:
        line([(x-r,y),(x+r,y)],white,8)
        line([(x,y-r),(x,y+r)],white,8)
    return im.convert("RGB") if not foreground else im

root=Path("assets/icons")
root.mkdir(parents=True,exist_ok=True)
make_icon(1024).save(root/"app_icon.png")
make_icon(1024,True).save(root/"app_icon_foreground.png")
print("Generated CiteCoach book + verification launcher icons")
