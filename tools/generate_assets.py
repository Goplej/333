#!/usr/bin/env python3
"""Build deterministic high-resolution CozyCraft noise textures.

Dependencies: numpy, Pillow. Assets deliberately retain fine stochastic detail so
ray-marched clouds do not tile or band at long view distances.
"""
from pathlib import Path
import argparse
import numpy as np
from PIL import Image, ImageFilter


def low_frequency(rng: np.random.Generator, size: int, cells: int) -> np.ndarray:
    small = rng.integers(0, 256, (cells, cells), dtype=np.uint8)
    image = Image.fromarray(small, "L").resize((size, size), Image.Resampling.BICUBIC)
    return np.asarray(image, dtype=np.float32)


def fractal_noise(rng: np.random.Generator, size: int, seed_offset: int) -> np.ndarray:
    result = np.zeros((size, size), np.float32)
    weight_sum = 0.0
    for cells, weight in ((16, .34), (32, .24), (64, .17), (128, .11), (256, .08), (512, .06)):
        result += low_frequency(rng, size, cells) * weight
        weight_sum += weight
    result /= weight_sum
    # Film-grain-like high frequency component prevents visible 2D interpolation bands.
    grain = rng.integers(0, 256, (size, size), dtype=np.uint8).astype(np.float32)
    return np.clip(result * .82 + grain * .18, 0, 255).astype(np.uint8)


def save_l(path: Path, array: np.ndarray) -> None:
    Image.fromarray(array, "L").save(path, optimize=False, compress_level=4)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--size", type=int, default=4096)
    args = parser.parse_args()
    out = args.output
    out.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(0xC02A11E)
    size = args.size

    base = fractal_noise(rng, size, 1)
    detail = fractal_noise(rng, size, 2)
    save_l(out / "cloud_base.png", base)
    save_l(out / "cloud_detail.png", detail)

    # RGB weather map: coverage, cloud type, precipitation potential.
    weather = np.dstack((
        fractal_noise(rng, size, 3),
        fractal_noise(rng, size, 4),
        fractal_noise(rng, size, 5),
    ))
    Image.fromarray(weather, "RGB").save(out / "weather_map.png", optimize=False, compress_level=4)

    water_size = size // 2
    h = fractal_noise(rng, water_size, 6).astype(np.float32) / 255.0
    gy, gx = np.gradient(h)
    nx, ny = -gx * 5.0, -gy * 5.0
    nz = np.ones_like(nx)
    inv = 1.0 / np.sqrt(nx * nx + ny * ny + nz * nz)
    normals = np.dstack(((nx * inv * .5 + .5), (ny * inv * .5 + .5), nz * inv))
    normals = np.clip(normals * 255.0, 0, 255).astype(np.uint8)
    # Preserve a little uncorrelated micro-normal information for close water.
    micro = rng.integers(-5, 6, normals.shape, dtype=np.int16)
    normals = np.clip(normals.astype(np.int16) + micro, 0, 255).astype(np.uint8)
    Image.fromarray(normals, "RGB").save(out / "water_normals.png", optimize=False, compress_level=4)

    blue_size = size // 2
    blue = rng.integers(0, 256, (blue_size, blue_size), dtype=np.uint8)
    # High-pass shaping is sufficient for temporal jitter and dithering.
    blurred = np.asarray(Image.fromarray(blue, "L").filter(ImageFilter.GaussianBlur(2.0)), dtype=np.int16)
    shaped = np.clip(128 + blue.astype(np.int16) - blurred, 0, 255).astype(np.uint8)
    save_l(out / "blue_noise.png", shaped)

    for path in sorted(out.glob("*.png")):
        print(f"{path.name}: {path.stat().st_size / 1048576:.2f} MiB")


if __name__ == "__main__":
    main()
