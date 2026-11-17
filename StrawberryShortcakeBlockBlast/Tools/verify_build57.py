#!/usr/bin/env python3
"""Validate build 57 bundled artwork and Swift source; no Apple compilation assumed."""
from pathlib import Path
import json, struct
root=Path(__file__).resolve().parents[1]
a=root/'BerryBlockBlast/Assets.xcassets'
assets=[
  'BerryClassic','SweetEndless','BerryStory','DailyHarvest','MoreAdventures',
  'BerryCollection','BerryUpgrades','StrawberrySchool','BerryInventory','CottageDecorations',
  'CollectionBadge','HarvestReward','ProgressStats','Milestone','Leaderboard',
  'Champion','BerryMarket','GardenStore','ShuffleHelper','GardenRotation','UndoHelper','UndoReward',
  'ScoreHeart','BestCrown','UndoIcon','ShuffleIcon','ShopBasket','StatsChart','HomeCottage',
  'BerryHint','StrawberryJukebox'
]
for asset in assets:
    d=a/(asset+'.imageset')
    manifest=json.loads((d/'Contents.json').read_text())
    image=d/manifest['images'][0]['filename']
    contents=image.read_bytes()
    assert contents[:8] == b'\x89PNG\r\n\x1a\n',image
    width,height=struct.unpack('>II',contents[16:24])
    assert width >= 100 and height >= 100,(asset,width,height)
project=(root/'project.yml').read_text()
assert 'MARKETING_VERSION: "0.5.8"' in project
assert 'CURRENT_PROJECT_VERSION: "1"' in project
assert 'IPHONEOS_DEPLOYMENT_TARGET: "16.0"' in project
text=(root/'BerryBlockBlast/BerryGameView.swift').read_text()
assert 'let target = candidates.first' in text
assert '.defaultScrollAnchor(' not in text
assert '.onTapGesture { location in' not in text
print(f'PASS: {len(assets)} offline icon PNG assets, deployment target/version and iOS16 source markers')
