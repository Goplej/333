HD assets are generated deterministically by tools/generate_assets.py and embedded in
the downloadable Cinematic ZIP. They are not duplicated as loose Git blobs to avoid
storing the same ~77 MiB twice (once loose and once in ZIP).

Files in release ZIP:
- cloud_base.png     4096x4096 L
- cloud_detail.png   4096x4096 L
- weather_map.png    4096x4096 RGB
- water_normals.png  2048x2048 RGB
- blue_noise.png     2048x2048 L
