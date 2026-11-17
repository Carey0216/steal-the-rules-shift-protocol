"""Pack the frames recorded by tools/record_demos.gd into WebP atlases."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "builds" / "recordings"
DEST = ROOT / "assets" / "demos"
FRAME_SIZE = (480, 180)
SHEET_SIZE = (FRAME_SIZE[0] * 4, FRAME_SIZE[1] * 5)
RECORDINGS = ("move", "strike", "dodge", "steal", "rule")

DEST.mkdir(exist_ok=True)
for name in RECORDINGS:
    frames = list(sorted((SOURCE / name).glob("*.png")))
    if len(frames) != 40:
        raise ValueError(f"{name} has {len(frames)} frames; expected 40")
    for index in range(2):
        atlas = Image.new("RGB", SHEET_SIZE)
        for cell, path in enumerate(frames[index * 20 : (index + 1) * 20]):
            with Image.open(path) as image:
                if image.size != FRAME_SIZE:
                    raise ValueError(f"{path} has unexpected size {image.size}")
                atlas.paste(image, ((cell % 4) * FRAME_SIZE[0], (cell // 4) * FRAME_SIZE[1]))
        destination = DEST / f"{name}-{index}.webp"
        atlas.save(destination, quality=88, method=6)
        print(f"{destination.name}: {destination.stat().st_size:,} bytes")
