"""Encode the native documentation capture as a compact looping GIF."""
from pathlib import Path
import sys
from PIL import Image

source, destination = map(Path, sys.argv[1:3])
paths = sorted(source.glob('frame-*.png'))
if len(paths) < 200:
    raise SystemExit('The capture is incomplete; record the full demonstration first.')

frames = [Image.open(path).convert('RGB') for path in paths]
# One palette avoids flickering gradients and glass highlights between frames.
samples = frames[::max(1, len(frames) // 18)]
atlas = Image.new('RGB', (560, 500 * len(samples)))
for index, image in enumerate(samples):
    atlas.paste(image, (0, 500 * index))
palette = atlas.quantize(colors=256)

# A short dissolve returns the emptied preview to its initial powered-off pose.
last_frame = frames[-1]
frames.extend(Image.blend(last_frame, frames[0], step / 10) for step in range(1, 11))
frames.extend([frames[0]] * 6)
indexed = [image.quantize(palette=palette, dither=Image.Dither.NONE) for image in frames]
destination.parent.mkdir(parents=True, exist_ok=True)
indexed[0].save(destination, save_all=True, append_images=indexed[1:], duration=50,
                loop=0, optimize=True, disposal=1)
print(f'Encoded {len(indexed)} frames: {destination} ({destination.stat().st_size:,} bytes)')
