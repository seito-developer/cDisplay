# cDisplay

**Display Any Aspect Ratio on macOS. Instantly.**

cDisplay applies a black mask overlay to your Mac screen, letting you preview 16:9, 4:3, 2.39:1, 1:1, or 9:16 — without leaving your workflow.

[Download for Mac — Free](https://github.com/seito-developer/cDisplay/releases/latest/download/cDisplay_v1.0.2.dmg) · macOS 14 Sonoma or later

---

## What It Does

cDisplay combines a resolution change with a black mask overlay (letterbox / pillarbox) to create a precise, pixel-accurate framing on your Mac display.

Pick a ratio from the menu bar. Your screen adapts instantly.

```
┌────────────────────────────┐
│██████████████████████████ │  ← black mask
├────────────────────────────┤
│                            │
│       YOUR CONTENT         │  ← visible area
│      (2.39:1 framing)      │
│                            │
├────────────────────────────┤
│██████████████████████████ │  ← black mask
└────────────────────────────┘
```

---

## Who It's For

**Video Editors** — Preview cinematic ratios (2.39:1, 4:3, 16:9) directly on your desktop while working in Final Cut Pro, Premiere, or DaVinci Resolve.

**Live Streamers** — Confirm your OBS output looks exactly right in 16:9 before going live. Capture precisely what your audience sees — no guesswork.

**Social Creators** — See how your content looks in 9:16 for TikTok & Reels, or 1:1 for Instagram, on your actual Mac screen before you export.

---

## How It Works

**1. Click the menu bar icon**
cDisplay runs as a lightweight menu bar app. Always accessible, never cluttering your Dock or workspace.

**2. Choose your aspect ratio**
Pick from 16:9, 4:3, 2.39:1, 1:1, or 9:16. Multiple resolution presets are available for each ratio.

**3. Your display adapts**
cDisplay changes the resolution and overlays a precise black mask. Your screen instantly shows the exact framing you need.

---

## Features

- **Hybrid mode** — resolution change + black mask overlay for pixel-perfect framing
- **5 aspect ratios** — 16:9, 4:3, 2.39:1, 1:1, 9:16 with multiple resolution presets each
- **Offset positioning** — Top / Center / Bottom
- **Works with OBS, Final Cut Pro, DaVinci Resolve**, and any screen capture tool
- **Smooth 0.25s fade animation** — no jarring transitions
- **Crash recovery** — display settings are always automatically restored
- **No screen recording permission required** — your privacy is protected
- **Free download. No subscription.**

---

## Download

[**Download cDisplay v1.0.2 (.dmg)**](https://github.com/seito-developer/cDisplay/releases/latest/download/cDisplay_v1.0.2.dmg)

Requirements: macOS 14 Sonoma or later

Or browse all releases: [GitHub Releases](https://github.com/seito-developer/cDisplay/releases)

---

## Build from Source

```bash
# Debug build
xcodebuild -scheme cDisplay -configuration Debug build

# Release build
xcodebuild -scheme cDisplay -configuration Release build

# Run tests
xcodebuild test -scheme cDisplay
```

Requirements: Xcode 15+, macOS 14.0 deployment target

---

## Support

cDisplay is a one-person project. If it saves you time in your workflow, a coffee is always appreciated — and helps keep development going.

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/seito)

---

## License

MIT

---

*cDisplay &copy; 2026*
