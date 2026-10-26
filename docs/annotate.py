"""Adds callout labels to a few of the rendered images (run by render_images.sh)."""
from PIL import Image, ImageDraw, ImageFont
import sys

FONT = "/System/Library/Fonts/Helvetica.ttc"
try:
    font = ImageFont.truetype(FONT, 30)
except OSError:
    font = ImageFont.load_default()

def label(d, text, anchor, target):
    """text box at anchor (x, y = box centre), leader line to target (x, y)."""
    l, t, r, b = d.textbbox((0, 0), text, font=font)
    w, h = r - l + 24, b - t + 18
    x, y = anchor
    box = (x - w / 2, y - h / 2, x + w / 2, y + h / 2)
    d.line([(x, y), target], fill="#222222", width=3)
    d.ellipse([target[0] - 7, target[1] - 7, target[0] + 7, target[1] + 7], fill="#d9480f", outline="white", width=2)
    d.rounded_rectangle(box, radius=8, fill="white", outline="#222222", width=2)
    d.text((x - w / 2 + 12 - l, y - h / 2 + 9 - t), text, fill="#111111", font=font)

def annotate(src, dst, items):
    im = Image.open(src).convert("RGB")
    d = ImageDraw.Draw(im)
    for text, anchor, target in items:
        label(d, text, anchor, target)
    im.save(dst)

annotate("images/exploded.png", "images/exploded_labeled.png", [
    ("1  Collar (black)",                   (1130, 215), (900, 260)),
    ("2  Diffuser disc in surround recess", (1100, 470), (800, 520)),
    ("3  Surround (white)",                 (1150, 640), (950, 620)),
    ("4  Back wall (white)",                 (1150, 820), (900, 800)),
    ("M3x40 bolt + hex nut (x3)",           (290, 150),  (420, 322)),
])
annotate("images/components_fit.png", "images/components_fit_labeled.png", [
    ("Diffuser disc",             (1140, 700), (800, 500)),
    ("LED strip (on edge)",       (1130, 190), (985, 330)),
    ("Baffle skirt",              (250, 250),  (452, 440)),
    ("Buck-converter pocket",     (250, 800),  (500, 560)),
    ("Bolt lug (x3)",             (1000, 90),  (762, 195)),
])
annotate("images/nut_trap_detail.png", "images/nut_trap_detail_labeled.png", [
    ("M3 nut drops in here", (1010, 330), (645, 480)),
    ("Hex pocket, closed by the surround lug", (1000, 880), (640, 595)),
])
print("labeled images written")
