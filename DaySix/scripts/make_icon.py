#!/usr/bin/env python3
"""Generate DaySix's original iOS app icon. Requires only Pillow."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

S = 1024
dest = Path(__file__).resolve().parent.parent / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"
dest.parent.mkdir(parents=True, exist_ok=True)

# Apple masks the icon shape. We provide full-bleed art, no words or fake iOS chrome.
base = Image.new("RGBA", (S, S))
pixels = base.load()
for y in range(S):
    for x in range(S):
        dx, dy = (x - 235) / 930, (y - 130) / 930
        a = max(0.0, 1.0 - (dx * dx + dy * dy) ** .5)
        vx, vy = (x - 810) / 890, (y - 740) / 900
        b = max(0.0, 1.0 - (vx * vx + vy * vy) ** .5)
        pixels[x, y] = (
            int(8 + 3 * a + 22 * b),
            int(16 + 85 * a + 9 * b),
            int(41 + 100 * a + 54 * b),
            255
        )

glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.arc((153, 153, 869, 869), 24, 306, fill=(32, 238, 221, 230), width=85)
gd.arc((153, 153, 869, 869), 310, 376, fill=(148, 121, 255, 210), width=85)
blurred = glow.filter(ImageFilter.GaussianBlur(55))
base = Image.alpha_composite(base, blurred)

rings = Image.new("RGBA", (S, S))
r = ImageDraw.Draw(rings)
r.arc((145, 145, 877, 877), 35, 294, fill=(5, 74, 112, 220), width=104)
r.arc((149, 149, 873, 873), 31, 294, fill=(65, 242, 218, 255), width=53)
r.arc((172, 172, 850, 850), 31, 294, fill=(165, 255, 247, 220), width=10)
r.arc((149, 149, 873, 873), 300, 385, fill=(156, 124, 246, 235), width=52)
r.polygon([(819, 248), (916, 319), (799, 370)], fill=(71, 238, 222, 255))
r.polygon([(205, 729), (107, 704), (215, 628)], fill=(88, 236, 224, 255))
base = Image.alpha_composite(base, rings)

shield_shadow = Image.new("RGBA", (S, S))
sd = ImageDraw.Draw(shield_shadow)
outer = [(513, 254), (741, 358), (741, 597), (688, 725), (513, 843), (339, 725), (283, 595), (283, 356)]
sd.polygon([(x + 8, y + 19) for x, y in outer], fill=(0, 0, 8, 220))
base = Image.alpha_composite(base, shield_shadow.filter(ImageFilter.GaussianBlur(26)))

frame = Image.new("RGBA", (S, S))
fd = ImageDraw.Draw(frame)
fd.polygon(outer, fill=(193, 224, 244, 255))
inner = [(513, 284), (713, 373), (713, 589), (659, 703), (513, 804), (368, 703), (312, 589), (312, 373)]
fd.polygon(inner, fill=(28, 45, 91, 255))
fd.line(outer + [outer[0]], fill=(250, 252, 255, 255), width=7, joint="curve")
core = [(513, 309), (693, 391), (693, 587), (641, 690), (513, 779), (388, 690), (335, 587), (335, 391)]
fd.polygon(core, fill=(9, 120, 147, 255))
fd.polygon([(513, 309), (693, 391), (693, 505), (513, 458)], fill=(21, 217, 203, 120))
fd.polygon([(513, 779), (641, 690), (693, 587), (693, 505), (513, 458)], fill=(105, 81, 218, 105))
fd.line(core + [core[0]], fill=(92, 225, 230, 195), width=8, joint="curve")
fd.line([(412, 558), (483, 634), (620, 482)], fill=(11, 40, 83, 210), width=64, joint="curve")
fd.line([(412, 544), (483, 619), (620, 469)], fill=(240, 250, 255, 255), width=51, joint="curve")
base = Image.alpha_composite(base, frame)
base.convert("RGB").save(dest, optimize=True)
print(dest)
