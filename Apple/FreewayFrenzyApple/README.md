# Freeway Frenzy — Apple (iOS / macOS)

A native SwiftUI + SceneKit build of Freeway Frenzy with a **chunky, blocky
Crossy-Road-style** look: fat voxel cars, stacked-box trees, a wide multi-lane
freeway, bright flat-shaded daylight, and a polished animated UI.

## Open & run

Open `FreewayFrenzy.xcodeproj` in **Xcode**, then pick a scheme:

- **FreewayFrenzy iOS** — iPhone/iPad simulator or device (portrait, iOS 17+).
- **FreewayFrenzy macOS** — desktop window (macOS 14+).

> Build with Xcode — the bare Command Line Tools can syntax-check the sources
> but cannot build/run the app or launch a simulator.

## Controls

- **iOS:** tap **PLAY** (or anywhere) to start · swipe left/right to change lanes ·
  hold a drag upward to boost, downward to brake · tap to retry. The menu car
  carousel switches your ride (arrows or swipe).
- **macOS:** Space/Enter start · ←/→ (or A/D) lanes · W/↑ boost · S/↓ brake ·
  M back to menu after a game over.

## What the rehaul changed

`GameView.swift` holds the SceneKit renderer and the SwiftUI overlay. The model
(`GameModel.swift`) is unchanged — only the presentation was reworked.

- **Camera (3D depth + the old "wrong zoom / blank band").** A perspective chase
  camera with a fixed **horizontal** field of view: the road is framed to width on
  any aspect ratio (tall phones just show more road ahead), while foreshortening
  gives real depth and a visible horizon. Earlier it was a flat orthographic camera
  that clipped the road on portrait phones.
- **No more black screen.** The old `sin`-driven day/night cycle that drove the
  sky to near-black was removed. The scene now uses a bright, stable sky, a
  daylight sun + ambient rig, and gentle *bright* distance fog that only fades the
  far spawn line to the sky colour.
- **Blocky & bigger.** Wider lanes (`laneSpacing`), chunkier cars (dark bumper
  trim, windshield, fat wheels, bold emissive lights), voxel stacked-box trees,
  clustered blocky rocks, bigger coins, hard chamfers, a punchy saturated palette,
  and SSAO removed so edges stay crisp.
- **Crash alignment.** Logic-space Y now maps so the player's collision row sits
  exactly on the player node — crashes happen where the cars visually overlap.
- **UI & transitions.** Interactive menu (PLAY button, car carousel, blocky car
  preview), game-over card (NEW BEST, RETRY / MENU buttons), springy pressable
  buttons, a "GO!" burst when a run starts, numeric content transitions, a screen
  vignette, and a sky-gradient fallback behind the GPU view.

### Tuning

The main world-space knobs live near the top of `LowPolyGameCoordinator`:

- `CameraProfile` / `cameraProfile` — per-platform chase camera framing. iOS
  portrait is intentionally closer with a bigger player car; macOS is wider and
  shows more freeway ahead.
- `laneSpacing` — road/lane chunkiness.
- `zPerLogic` — how far back traffic spawns. It's paired with the scene fog
  values in `CameraProfile` so cars emerge *out of the fog* instead of popping
  in. If you change one, re-check the other.

## App Store / TestFlight checklist

Use this project as the App Store product. Archive and upload from full Xcode,
not the standalone Command Line Tools.

- Team: `3FYAZJF2ND` (or the active Apple Developer Program team).
- iOS bundle ID: `com.freewayfrenzy.game`.
- macOS bundle ID: `com.freewayfrenzy.game.mac`.
- Display name: `Freeway Frenzy`.
- Version: `1.0`; increment the build number for every upload.
- App Store category: Games.
- Suggested SKU: `freeway-frenzy-ios-001`.
- Privacy: no tracking unless analytics or ads are added. With only local
  high-score storage in `UserDefaults`, the app should not declare collected
  user data.

Before uploading:

- Run on iPhone, iPad, and macOS from Xcode.
- Confirm no `Fatal error: Index out of range`.
- Confirm the garage car colour matches the selected swatch.
- Confirm the menu fits on small iPhones and iPad.
- Confirm traffic and coins spawn from the fog/offscreen instead of popping near
  the player.
- Confirm Xcode shows no AppIcon unassigned child warning.

## Cloud handoff

The clean cloud branch is `codex/freewayfrenzy-app-store-ready`.

```bash
git clone https://github.com/seanwirkus/FreewayFrenzy.git
cd FreewayFrenzy
git switch codex/freewayfrenzy-app-store-ready
open Apple/FreewayFrenzyApple/FreewayFrenzy.xcodeproj
```

The branch intentionally keeps unrelated ESP32/LVGL generated churn out of the
Apple game commit so the Xcode project can be opened cleanly from another Mac.
