#!/usr/bin/env python3
"""Generate an original 1024px berry-hat mascot icon. Requires Pillow.
Run before xcodegen: python3 Tools/generate_icon.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 1024
SCALE = 2
N = SIZE * SCALE
img = Image.new("RGB", (N, N), "#fff0ec")
pix = img.load()
for y in range(N):
    t = y / N
    for x in range(N):
        glow = max(0.0, 1 - math.hypot((x / N - .34) * 1.35, (t - .22) * 1.0))
        pix[x, y] = (255, int(214 + 22 * glow + 15 * t), int(224 + 14 * glow + 6 * t))

def B(xy): return tuple(int(v * SCALE) for v in xy)
def ellipse(b, color, outline=None, width=1):
    draw.ellipse(B(b), fill=color, outline=outline, width=width * SCALE)
def rr(b, radius, color, outline=None, width=1):
    draw.rounded_rectangle(B(b), radius=radius*SCALE, fill=color, outline=outline, width=width*SCALE)
def polygon(pts, color): draw.polygon([B(p) for p in pts], fill=color)

draw = ImageDraw.Draw(img)
# Scattered painted sugar-sprinkle details.
for x,y,r in [(160,135,15),(856,165,20),(142,745,14),(843,772,16),(214,886,8),(820,389,10)]:
    ellipse((x-r,y-r,x+r,y+r), "#fff9f0")
# Ribbon of berry-shaped tiles.
for i, color in enumerate(["#ff879d", "#f1486b", "#8ccf8b"]):
    rr((166+i*244,765,378+i*244,964),32,"#fffdf8")
    rr((180+i*244,779,364+i*244,950),26,color)
    rr((198+i*244,793,311+i*244,812),10,"#ffffff")
# Hair cloud.
ellipse((242,270,784,776), "#a83c2b")
for x,y,rad in [(275,542,103),(306,658,80),(710,553,107),(729,656,86),(379,690,85),(599,694,83)]:
    ellipse((x-rad,y-rad,x+rad,y+rad),"#bf4c31")
# Neck and rosy cheeks.
ellipse((454,650,580,787),"#ffd3ad")
ellipse((305,334,722,728),"#ffdab2")
ellipse((338,550,447,622),"#ffaba6")
ellipse((591,550,692,622),"#ffaba6")
# Face highlights and eyes.
for x in (423,598):
    ellipse((x-29,515,x+29,588),"#62382e")
    ellipse((x-13,523,x+4,545),"#ffffff")
    ellipse((x+8,556,x+14,564),"#ffffff")
# Smile arc.
draw.arc(B((459,571,568,674)),start=20,end=160,fill="#9a3d45",width=9*SCALE)
for x,y in [(392,589),(407,600),(626,587),(639,599),(380,606),(648,614)]:
    ellipse((x-5,y-5,x+5,y+5),"#bb7868")
# Front hat brim and crown with pale pink edge.
ellipse((152,225,876,480),"#e77094")
ellipse((156,209,870,446),"#ffb6cd")
ellipse((286,97,755,359),"#fdaac7")
rr((298,300,740,351),22,"#e14c76")
# Light green stripes on a looped bow.
ellipse((588,150,793,281),"#faffed")
ellipse((595,162,785,273),"#8ac878")
for delta in (0, 64, 125):
    polygon([(613+delta,168),(631+delta,166),(684+delta,273),(662+delta,269)],"#faffed")
# Strawberry medallion on hat.
ellipse((617,180,729,309),"#f03952")
polygon([(627,258),(720,258),(681,325)],"#f03952")
for x,y in [(648,232),(686,242),(674,279),(703,270)]:
    ellipse((x-4,y-5,x+4,y+5),"#ffe0a3")
polygon([(622,192),(644,169),(671,187),(696,165),(716,193),(687,211),(661,202)],"#4da85d")
# Strawberry-like spots on the hat brim.
for x,y in [(256,344),(352,396),(499,385),(805,344)]:
    ellipse((x-21,y-13,x+21,y+24),"#f48aa1")
    polygon([(x-19,y-7),(x,y-23),(x+20,y-8)],"#65a86d")
# Crisp gloss and slight outline.
draw.arc(B((164,222,859,451)),start=190,end=350,fill="#fff4f6",width=9*SCALE)
img = img.resize((SIZE,SIZE), Image.Resampling.LANCZOS)
output = Path(__file__).resolve().parents[1] / "BerryBlockBlast/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
output.parent.mkdir(parents=True, exist_ok=True)
img.save(output, optimize=True)
print(f"Created {output} ({output.stat().st_size:,} bytes)")
