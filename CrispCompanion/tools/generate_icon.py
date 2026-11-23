"""Generate a temporary native PNG AppIcon for Build 1. No third-party artwork."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
icon_dir = root / "Resources/Assets.xcassets/AppIcon.appiconset"
icon_dir.mkdir(parents=True, exist_ok=True)
size = 1024
image = Image.new("RGB", (size, size), (18, 23, 30))
draw = ImageDraw.Draw(image)
# Layered warm enamel badge, deliberately no VeSync or COSORI logos.
for i in range(160, 0, -1):
    tone = (max(25, 67 - i//4), max(22, 45 - i//5), max(24, 42 - i//5))
    draw.rounded_rectangle((115-i//7, 115-i//7, 909+i//7, 909+i//7), radius=228, fill=tone)
draw.rounded_rectangle((160, 160, 864, 864), radius=205, fill=(43, 46, 54))
draw.ellipse((310, 325, 715, 735), outline=(251, 184, 105), width=42)
draw.arc((377, 275, 648, 675), 80, 287, fill=(255, 119, 79), width=55)
draw.arc((439, 349, 584, 660), 85, 265, fill=(255, 210, 139), width=40)
path = icon_dir / "AppIcon-1024.png"
image.save(path, "PNG")
(icon_dir / "Contents.json").write_text(json.dumps({"images":[{"filename":path.name,"idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}, indent=2))
print("Generated temporary AppIcon", path)
