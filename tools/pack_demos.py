"""Pack the frames recorded by tools/record_demos.gd into WebP atlases."""

from pathlib import Path
import sys

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "builds" / "recordings"
DEST = ROOT / "assets" / "demos"
FRAME_SIZE = (576, 258)
SHEET_SIZE = (FRAME_SIZE[0] * 3, FRAME_SIZE[1] * 5)
RECORDINGS = ("move", "strike", "dodge", "steal", "rule")
if "--context" in sys.argv:
    RECORDINGS = tuple(f"context-{index:02d}" for index in range(20))
if "--supply" in sys.argv:
    RECORDINGS = ("context-12", "context-13")
for option in sys.argv[1:]:
    if option.startswith("--lesson="):
        RECORDINGS = (f"context-{int(option.split('=', 1)[1]):02d}",)

DEST.mkdir(exist_ok=True)
for name in RECORDINGS:
    frames = list(sorted((SOURCE / name).glob("*.png")))
    if len(frames) != 60:
        raise ValueError(f"{name} has {len(frames)} frames; expected 60")
    for index in range(4):
        atlas = Image.new("RGB", SHEET_SIZE)
        for cell, path in enumerate(frames[index * 15 : (index + 1) * 15]):
            with Image.open(path) as image:
                if image.size != FRAME_SIZE:
                    raise ValueError(f"{path} has unexpected size {image.size}")
                atlas.paste(image, ((cell % 3) * FRAME_SIZE[0], (cell // 3) * FRAME_SIZE[1]))
        destination = DEST / f"{name}-{index}.webp"
        atlas.save(destination, quality=83 if name.startswith("context-") else 88, method=4)
        print(f"{destination.name}: {destination.stat().st_size:,} bytes")
