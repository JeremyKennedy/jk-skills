# Recording

The goal is a clip in which someone else can see the tap and the result. Three
things break that, and all three were hit in one session:

1. `screenrecord` on a headless emulator finalizes after about two seconds,
   whatever `--time-limit` says. The clip ends before the action.
2. `show_touches` is a system overlay, drawn outside the app's compositor, and a
   WebView screencast does not carry it. Even a working `screenrecord` clip gets
   its touch dots from the system layer, so nothing the page sends includes them.
3. The recording stops when the action "looks done", before the result's content
   has painted over the network.

## The approach

`scripts/record-tap.mjs` records the page through its DevTools socket:

- `Page.startScreencast` sends a frame whenever the page repaints. That is
  exactly what we want: static periods cost nothing, and every visible change is
  captured.
- Before dispatching the touch, it paints a marker at that point and lets it
  fade. The touch is real (`Input.dispatchTouchEvent`); the marker only makes
  the point visible.
- Frames are timestamped and written into an ffmpeg `concat` list with per-frame
  durations, so each frame stays on screen as long as it did live. Encoding at a
  fixed rate instead would speed through the static start and blur past the
  transition.
- `waitFor` keeps recording until the text you expect is on screen. Use it for
  anything that arrives over the network.

`screenrecord` is still the right tool for a non-WebView app on a real device,
where it does not truncate. In that case, enable the system overlay for the clip:

```bash
adb shell settings put system show_touches 1
adb shell settings put system pointer_location 1
adb shell screenrecord --bit-rate 8000000 --time-limit 15 /sdcard/clip.mp4
# then, after the clip finishes:
adb pull /sdcard/clip.mp4 clip.mp4
adb shell settings put system show_touches 0
```

Do not kill `screenrecord` early: interrupting it truncates the file. Let the
time limit end it, then pull.

## Check the clip before handing it over

```bash
ffprobe -v error -show_entries format=duration -of default=nw=1 clip.mp4
ffmpeg -y -sseof -0.2 -i clip.mp4 -frames:v 1 last.png
ffmpeg -y -i clip.mp4 -vf "select='eq(n\,0)+eq(n\,15)+eq(n\,40)'" -fps_mode passthrough frame-%02d.png
```

Look at all four images:

- the first frame is the state before the tap, with the target visible;
- one of the middle frames carries the tap marker;
- the last frame shows the result's content, not a spinner, an empty pane, or
  the previous screen.

A clip whose last frame is still loading is worse than no clip: it invites the
reader to conclude the feature does not work.

## Delivering

- MP4 plays in a PR description when attached; a secret gist with the file
  linked works too. GIF is for places that will not play video, and is much
  larger for the same length, so keep it short.
- Say plainly that the tap marker is drawn for the recording. A reviewer who
  finds out later loses trust in the rest of the clip.
- Keep the clip short: the tap, the transition, the result. Nothing before or
  after helps the reader.
