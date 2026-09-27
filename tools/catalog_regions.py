"""Read atlas alpha bounds and write Godot regions; never rewrites source images.
Run with Python + Pillow + scipy. Generated images are kept at original quality.
"""
from pathlib import Path
import json
from PIL import Image
from scipy import ndimage
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
FAMILIES = 'small_home medium_home modern_home low_apartments apartments tower store bakery restaurant cafe supermarket workshop service office public clinic'.split()
manifest = {}
for country in ('ar', 'jp', 'it', 'br', 'us'):
    image = Image.open(ROOT / f'assets/catalog/{country}.png')
    labels, _ = ndimage.label(np.array(image.getchannel('A')) > 50)
    boxes = []
    for region in ndimage.find_objects(labels):
        if region:
            y, x = region
            if (y.stop-y.start)*(x.stop-x.start) > 5000:
                boxes.append([x.start, y.start, x.stop-x.start, y.stop-y.start])
    assert len(boxes) == 16, (country, len(boxes))
    # Row baselines are consistent even though towers start higher than shops.
    boxes.sort(key=lambda b: b[1] + b[3])
    ordered = []
    for row in range(4):
        ordered.extend(sorted(boxes[row*4:row*4+4], key=lambda b: b[0]))
    folder = ROOT / 'assets/catalog' / country
    folder.mkdir(exist_ok=True)
    manifest[country] = {}
    for family, box in zip(FAMILIES, ordered):
        manifest[country][family] = box
        (folder / f'{family}.tres').write_text(
            '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
            f'[ext_resource type="Texture2D" path="res://assets/catalog/{country}.png" id="1"]\n\n'
            '[resource]\natlas = ExtResource("1")\n'
            f'region = Rect2({", ".join(map(str, box))})\nfilter_clip = true\n'
        )
(ROOT / 'assets/catalog/regions.json').write_text(json.dumps(manifest, indent=2)+'\n')
