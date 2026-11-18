# Frickbear's 3 — iOS IPA wrapper

An unofficial iOS app that bundles the GameMaker HTML5 build of
**Five Nights at Frickbear's 3** locally and runs it fullscreen with on-screen
touch controls.

This is **not** a from-scratch native port (that would require the original
GameMaker source project, which only the developer has). It is still the web
build under the hood — but packaged as a native app it:

- loads from the app bundle, so **no network, no ads, no Safari UI**
- gets a real fullscreen canvas, audio unlocked by a native tap, and automatic
  pause/resume when the app backgrounds
- adds a configurable gamepad overlay plus an optional tap-to-mouse mode
- weighs roughly **80–100 MB**, far below your 2.3 GB ceiling

> Personal, non-commercial use only. See [CREDITS.md](CREDITS.md).

---

## Build & install (no Mac required)

You need: a GitHub account, this folder uploaded as a repo, your Windows PC,
your iPhone on the same Wi-Fi/USB, a free Apple ID, and
[Sideloadly](https://sideloadly.io/) (free).

### 1. Put the files on GitHub

Create a new **public** repository on GitHub and upload this whole folder
(the `Frickbears3iOS` folder contents — `project.yml`, `App/`, `Scripts/`,
`.github/`, `Game/`, `README.md`, `CREDITS.md`).

Public repos get free macOS GitHub Actions minutes. Private repos also work
but consume your monthly free quota.

### 2. Build the IPA in the cloud

1. Open the repo on GitHub → **Actions** tab.
2. Select **Build Frickbears3 iOS IPA** → **Run workflow** → green button.
3. Wait ~5–10 minutes. The workflow:
   - downloads the ~80 MB web build into `Game/`
   - generates the Xcode project with XcodeGen
   - builds an unsigned `.app` and zips it into an `.ipa`
4. Click the completed run → **Artifacts** → download
   **Frickbears3iOS-IPA** (a .zip). Extract it to get `Frickbears3iOS.ipa`.

### 3. Sign & install on your iPhone with Sideloadly (Windows)

1. Install and open [Sideloadly](https://sideloadly.io/).
2. Connect your iPhone via USB and trust the computer prompt.
3. Enter your **Apple ID + password** (an app-specific password is safest —
   generate one at <https://appleid.apple.com>).
4. Drag `Frickbears3iOS.ipa` into Sideloadly.
5. Optionally set a custom bundle ID so it doesn't clash with other sideloaded
   apps (e.g. `com.yourname.frickbears3`).
6. Click **Start**. It signs with your free personal team and installs.
7. On the iPhone: **Settings → General → VPN & Device Management → your Apple
   ID → Trust**.

Free Apple ID signing lasts **7 days**; just repeat step 3–6 to refresh. A paid
Apple Developer account lasts a year.

---

## Controls

| On-screen | Sends |
| --- | --- |
| ▲ ▼ ◀ ▶ | Arrow keys (minigame movement) |
| A | Space |
| B | Escape |
| X | E |
| Y | Tab |
| L / R | Q / F |
| II | Pause / resume |
| ⚙ | Open Settings |
| 🔍 1× | Cycle game zoom: 1× → 2× → 3× → 1× |
| MOUSE: ON | Tap anywhere to send mouse clicks to the game |

- **MOUSE: ON** is what you want in the office for doors, the monitor and
  camera tabs. Turn it off for minigames that use direct touch movement.

## Settings (⚙)

All options are saved on the device instantly — **no rebuild required**.

- **Button Mapping** — tap any action, choose the key it should send. **Reset**
  restores the defaults shown in the table above.
- **Game Speed** — pick from 0.25× to 2.0× (default 1.0×).
  ⚠️ **Experimental:** the engine has no official speed control, so this scales
  the game's internal clock. It can affect timing-sensitive logic — set it
  back to **1.00× (normal)** if anything behaves oddly.
- **FPS Counter** / **Memory Counter** — toggle a small HUD at the top of the
  screen showing rendered frames per second and the app's real RAM usage in MB.
- **Minigame Zoom Button** — show/hide the 🔍 button. Tap it to cycle 1×/2×/3×
  zoom (handy for **Minesweeper**). While zoomed: **tap to click**, **drag to
  pan** the canvas. Zoom wins over MOUSE mode until you return to 1×.
- **Reset All** (top right) restores every option and all key mappings.

> Turning the zoom button off while zoomed in automatically returns the game
> to 1× so you never get stuck zoomed in.

---

## Troubleshooting

- **"Could not parse file list"** in the build log — the CDN changed its
  `index.html` layout. Open the URL and update the regex in
  `Scripts/fetch-web-build.sh`.
- **Game stuck on "Downloading..."** — make sure every file listed in
  `manifestFiles()` exists inside `Game/` (`runner.data`, `runner.js`,
  `runner.wasm`, `audio-worklet.js`, `game.unx` are the big ones).
- **Sideloadly: "provisioning profile missing / could not verify app"** — check
  that you used a real Apple ID, unlock with an app-specific password, and
  make sure the bundle ID is unique.
- **App crashes on launch / goes black** — your device may be low on RAM.
  Close other apps, restart the phone, and reinstall. The bundle itself is
  small; crashes at this size are almost always memory pressure on the device.
- **Rotation** — the app is landscape-only. Turn the phone sideways before
  tapping **TAP TO START**.

---

## If you have a Mac instead

You can skip GitHub Actions:

```bash
cd Frickbears3iOS
bash Scripts/fetch-web-build.sh
brew install xcodegen
xcodegen generate
open Frickbears3iOS.xcodeproj
```

Then in Xcode pick your device/team and **Product → Archive → Distribute App**
(Development) to install directly, with Xcode handling the signing.
