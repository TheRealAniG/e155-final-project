"""Usage: python FPGA/tools/import_car.py "path/to/car.png" (requires Pillow)."""
import argparse
from pathlib import Path
from PIL import Image

parser = argparse.ArgumentParser(description="Fit a car image into a transparent 32x32 sprite.")
parser.add_argument("image", type=Path)
args = parser.parse_args()
out = Path(__file__).resolve().parents[1] / "assets"
out.mkdir(exist_ok=True)
with Image.open(args.image) as source:
    src = source.convert("RGBA")
src.thumbnail((32, 32), Image.Resampling.NEAREST)
canvas = Image.new("RGBA", (32, 32))
canvas.paste(src, ((32-src.width)//2, (32-src.height)//2))
pixels = list(canvas.getdata())
opaque = [px[:3] for px in pixels if px[3] >= 128]
if not opaque:
    parser.error("The image has no visible pixels.")
strip = Image.new("RGB", (len(opaque), 1))
strip.putdata(opaque)
indexed = strip.quantize(colors=15, dither=Image.Dither.NONE)
indices = iter(indexed.getdata())
bitmap = [next(indices)+1 if px[3] >= 128 else 0 for px in pixels]
palette = [0, 0, 0] + indexed.getpalette()[:45]
palette += [0] * (48-len(palette))
(out/"car.mem").write_text("".join(f"{i:x}\n" for i in bitmap))
(out/"car_palette.mem").write_text("".join(bytes(palette[i:i+3]).hex()+"\n" for i in range(0,48,3)))
print("Ready:", out/"car.mem", "and", out/"car_palette.mem")
