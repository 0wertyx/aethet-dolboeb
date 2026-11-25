# Original AETHER desktop icons

This module uses the **32 original AETHER icons** supplied in `AETHER_32_Icons(1).zip`.
The Roblox GUI already supports the complete 8×4 sprite atlas via
`src/shared/Icons.luau`, used by the navigation **and the HUD dock**.

## Import the icons into Roblox

1. Download the 8×4 atlas (1792×896) supplied alongside this update,
   `AETHER_original_icons_clean_atlas.png`. The images are derived from
   the original 224×224 PNGs and have the text baked into the originals
   removed so they remain readable as 24px icons.
2. In Roblox Creator Dashboard, upload that **PNG** as an image asset
   owned by the place's creator/group; wait for moderation and availability.
3. In AETHER, go to **Dashboard → AETHER icon atlas Roblox asset ID**
   and enter the numeric asset ID.
4. The 16 navigation buttons and 3 HUD dock buttons will display their
   corresponding original purple icons, with text-only fallback until the
   asset is configured.

GitHub raw PNG URLs cannot be used directly in `ImageLabel.Image`.
Do not substitute a GitHub URL for a Roblox asset ID.

The existing `tools/export_desktop_icons.py` can export the original 32
PNG images from a desktop release if required. Its atlas also uses 8×4 tiles
of 224×224 pixels and remains compatible with `src/shared/Icons.luau`.

Atlas order:

```
Home Dashboard HUD Fonts Themes World_FX Indicators Simulator
Workshop Downloads Plugins Extensions AI_Assistant Music Media Games
Console Logs Settings Profile Health Performance Update About
Tests Debug Bridge Launch Files Assets Cloud Favorites
```
