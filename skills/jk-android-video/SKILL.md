---
name: jk-android-video
version: "1.0.0"
description: "Use when recording an Android app's UI as video or GIF evidence: PR and bug-report clips, taps that must be visible, emulator or device, APK build and install, WebView-driven apps, or when screenrecord produced a clip that is too short or shows no touch."
---

# Android video recording

A clip is evidence. It has to show the thing you claim, including the tap that
caused it, and it has to end after the result has painted. Most failures in this
work come from a clip that technically exists but proves nothing: two seconds of
the wrong screen, no visible touch, or a recording that stops before the result.

## When to use

- Recording an Android app for a PR, a bug report, or to show someone a change.
- A previous clip was too short, showed no tap, or ended before the result.
- Driving an app that is a WebView (Capacitor, Cordova, a remote page).
- Building and installing a debug APK to record a branch, not a release.

## The shape of the job

1. **Decide the claim.** One sentence: what should the clip show happening. If
   it needs two, record two clips. A clip that shows a tap and a result is worth
   more than a longer one that shows the surrounding app.
2. **Get a runtime.** A connected device comes first (`adb devices`). Without
   one, boot an emulator: `references/emulator-setup.md`.
3. **Build and install the APK** you actually want to show. A stale install is
   the most common reason a clip "does not reproduce": Gradle says every task is
   up to date, so check the APK's timestamp against the change, and reinstall
   after every rebuild (`adb install -r`).
4. **Drive the app** to the state the clip starts from. WebView apps give you the
   page's DevTools socket, which is far more reliable than coordinate taps:
   `references/webview-cdp.md`.
5. **Record with the tap visible** using `scripts/record-tap.mjs`. It paints a
   tap marker at the point where a real touch is dispatched and keeps each frame
   for as long as it was on screen, then encodes an MP4.
6. **Verify the clip.** Extract the first, a middle, and the last frame, and look
   at them. The first should be the state before the tap, one should carry the
   marker, and the last must show the result's content, not an empty shell that
   was still loading when you stopped.

## Recording

```bash
# The chip to tap, found by its label; returns the centre in CSS pixels.
node scripts/record-tap.mjs \
  --ws "$(curl -s http://127.0.0.1:9444/json | jq -r '.[0].webSocketDebuggerUrl')" \
  --out clip.mp4 \
  --tap "(() => { const b = [...document.querySelectorAll('button')].find((x) => (x.getAttribute('aria-label') || '').includes('idea.md')); if (!b) return null; const r = b.getBoundingClientRect(); return { x: r.x + r.width / 2, y: r.y + r.height / 2, waitFor: 'idea one|first short' }; })()" \
  --pre 1400 --post 9000
```

`waitFor` is optional and does the thing a fixed `--post` cannot: it keeps the
recording alive until the text you expect is painted, then stops. Use it whenever
the result arrives over the network (a file, a page, a list).

Why not `adb shell screenrecord`:

- On a headless emulator it finalizes after about two seconds regardless of
  `--time-limit`, so the clip ends before the action.
- Android's `show_touches` is a system overlay, drawn outside the app's
  compositor. A WebView screencast never carries it, and when screenrecord does
  work, the clip is still truncated.

The marker the script paints is not a fake click. The touch is dispatched with
`Input.dispatchTouchEvent` at those coordinates; the marker only makes the point
visible for the viewer. Say so when you hand the clip over, especially in a PR.

Then, to make a GIF for a place that will not play video:

```bash
ffmpeg -y -i clip.mp4 -vf "fps=10,scale=390:-1:flags=lanczos" -loop 0 clip.gif
```

## Verify before sending

```bash
ffprobe -v error -show_entries format=duration -of default=nw=1 clip.mp4
ffmpeg -y -sseof -0.2 -i clip.mp4 -frames:v 1 last.png
```

Open `last.png`. If it shows a spinner, an empty pane, or the screen before the
result, the clip is not evidence yet: extend `waitFor`/`--post` and record again.
Also check that the marker is visible in at least one frame near the start.

## Traps that cost an hour each

- **The install is stale.** Gradle reports `up-to-date` and the APK on disk does
  not contain your change. Compare the APK timestamp with the commit, then
  `adb install -r`. The app restarts and gets a new WebView PID, so the DevTools
  forward must be recreated.
- **Port collisions on forwards.** `adb forward tcp:9444 ...` fails with
  "Address already in use" when another session holds the port. Pick a fresh
  port and check the target's title and URL before driving it; an old target
  looks perfectly alive.
- **Hidden overlays fool existence checks.** A surface can cover the element you
  are about to tap while its DOM node still exists. Check what is actually at
  the point: `document.elementFromPoint(x, y)` must be the element or inside it.
- **Reloading kills the execution context, not the socket.** After
  `location.reload()` wait for the app to paint again; do not reconnect to an
  already-open socket (it hangs), and re-read `/json` if the target changed.
- **Settings that apply once.** Some preferences are read when a view is built
  and are not reactive. Set the value the app itself persists (its settings API
  or store), then reload so the view is rebuilt with it. Toggling after the fact
  leaves the view unchanged.
- **React inputs ignore `el.value = x`.** Use the native setter and dispatch an
  `input` event, or the framework never sees the change.
- **The toast is in the way.** Remove app banners before the capture starts, not
  during it, and remove the smallest container that holds only the banner.
- **Overlays close with Back.** `adb shell input keyevent 4` is the quickest way
  out of a sheet that blocks the page.

## References

- `references/emulator-setup.md` — SDK, AVD, boot, and what to install where.
- `references/webview-cdp.md` — finding and driving a WebView: forward, targets,
  evaluating, tapping, typing, and the visibility check.
- `references/recording.md` — how the marker and the frame timing work, and how
  to check a clip objectively.
