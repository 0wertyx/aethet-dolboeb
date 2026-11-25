#!/usr/bin/env python3
"""Extract the 32 original AETHER desktop icons into one Roblox atlas.

Usage:
  python tools/export_desktop_icons.py "AETHER_Build(1).zip" assets/icons
Requires Pillow (python -m pip install Pillow).
Upload the resulting AETHER_original_icons_atlas.png as a Roblox image asset,
then enter its numeric ID in Dashboard -> AETHER icon atlas Roblox asset ID.
"""
import io
import json
import sys
import zipfile
from pathlib import Path
from PIL import Image

def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit('Usage: export_desktop_icons.py APP_ZIP [OUTPUT_DIR]')
    archive=Path(sys.argv[1])
    target=Path(sys.argv[2] if len(sys.argv)>2 else "assets/icons")
    target.mkdir(parents=True,exist_ok=True)
    order=[
        "Home","Dashboard","HUD","Fonts","Themes","World_FX","Indicators","Simulator",
        "Workshop","Downloads","Plugins","Extensions","AI_Assistant","Music","Media","Games",
        "Console","Logs","Settings","Profile","Health","Performance","Update","About",
        "Tests","Debug","Bridge","Launch","Files","Assets","Cloud","Favorites",
    ]
    atlas=Image.new("RGBA",(1792,896),(0,0,0,0))
    mapping={}
    with zipfile.ZipFile(archive) as z:
        available={Path(name).name:name for name in z.namelist()}
        for i,name in enumerate(order):
            filename=f"{i+1:02d}_{name}.png"
            if filename not in available:
                raise SystemExit(f"Icon missing: {filename}")
            raw=z.read(available[filename])
            icon=Image.open(io.BytesIO(raw)).convert("RGBA")
            if icon.size!=(224,224):
                raise SystemExit(f"Unexpected size for {filename}: {icon.size}")
            (target/filename).write_bytes(raw)
            x=(i%8)*224
            y=(i//8)*224
            atlas.paste(icon,(x,y))
            mapping[name]={"x":x,"y":y,"size":224}
    atlas.save(target/"AETHER_original_icons_atlas.png",optimize=True)
    (target/"atlas-map.json").write_text(json.dumps(mapping,indent=2)+"\n",encoding="utf-8")
    print(f"Extracted 32 original PNGs and atlas into {target}")

if __name__=="__main__":
    main()
