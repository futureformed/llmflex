# Art & branding assets

Drop design source files here. This is the spec + checklist for what to provide
so the assets can be wired into the app. There are **three separate assets** —
they have different requirements, so read each section.

> Rule of thumb: a **mockup** (e.g. of the popover) is *reference only* — the UI
> is rebuilt in SwiftUI from specs, not from an image. An **icon file** is the
> actual deliverable that ships. Know which one you're handing over.

---

## 1. App icon — `icon-1024.png`

Shown in Finder, Applications, the Dock (when relevant), and the DMG.

- **Provide:** a single **1024×1024 PNG** with transparency. That's the master;
  all smaller sizes and the final `.icns` are generated from it.
- **macOS does NOT auto-round icons** (unlike iOS). If you want the standard
  rounded-square look, bake the rounded-rectangle shape + subtle shadow *into
  the artwork*, sitting inside the canvas with ~10% transparent margin. A
  full-bleed square renders as a hard square.
- Keep it **bold and simple** — it must still read at 16px.

Build wiring (handled in code once the PNG lands): generate the iconset with
`sips`/`iconutil` → `.icns` → set `CFBundleIconFile` in `build.sh`'s Info.plist
and copy the `.icns` into `Contents/Resources`.

## 2. Menu-bar icon — `menubar.svg` (or an SF Symbol name)

The glyph in the macOS menu bar. **This is not the colourful app icon.**

- macOS menu-bar icons are **template images**: **monochrome, pure black on a
  transparent background**. The system tints them for light/dark mode
  automatically — do not add colour.
- **Provide:** a simple single-shape glyph as **SVG or PDF** (vector preferred),
  or a PNG at **18pt** (18 / 36 / 54 px for @1x/@2x/@3x). Roughly square,
  readable at ~18px tall.
- Or: just name an **SF Symbol** to use instead of a custom glyph (current
  default is `arrow.left.arrow.right.circle.fill`).
- Design note: strip the app icon down to one bold shape. Fine detail dies at
  this size.

## 3. In-app look & feel — specs, not files

The popover's visual system lives in `Sources/LLMFlex/Theme.swift`. For this,
provide **values**, not images:

- **Hex codes** for: accent, "active" state colour, any background tints.
  (Current: accent `#5E48A8`, active green `#34A853`.)
- Any corner-radius / spacing direction.
- **Font:** recommend keeping the **system font** — a menu-bar utility looks
  best with it, and a custom typeface adds bundle weight and feels out of place.
  Can be overruled.
- Reference mockups of the popover are welcome — drop them here as
  `mockup-*.png`. They guide the SwiftUI rebuild; they aren't shipped.

---

## Handoff checklist

- [ ] `icon-1024.png` — 1024×1024, transparent, rounded shape baked in
- [ ] `menubar.svg` (monochrome, transparent) **or** chosen SF Symbol name
- [ ] Palette: accent / active / background hex codes
- [ ] (optional) `mockup-*.png` reference for the popover
- [ ] (later) DMG background + window layout — parked until icon & palette settle
