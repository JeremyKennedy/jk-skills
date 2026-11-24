# Driving a WebView app

Capacitor, Cordova and remote-page apps render in an Android WebView. A debug
build exposes the page's DevTools socket, which lets you read the DOM, check what
is actually visible, fill fields, and dispatch real touches. That is far more
reliable than tapping coordinates from a screenshot.

## Find the socket

```bash
adb shell cat /proc/net/unix | grep -o 'webview_devtools_remote_[0-9]*' | sort -u
PID=$(adb shell pidof <package> | tr -d '\r')
adb forward tcp:9444 localabstract:webview_devtools_remote_$PID
curl -s http://127.0.0.1:9444/json
```

The target is one JSON entry per page. Read its `title` and `url` before driving
it; if they are not your app, another session's forward is on that port. A port
in use fails loudly with `cannot bind listener: Address already in use`, so pick
another number rather than reusing one blindly.

Reinstalling or force-stopping the app changes the PID, and the forward must be
removed and recreated. The socket URL itself changes too:

```bash
adb forward --remove tcp:9444
adb forward tcp:9444 localabstract:webview_devtools_remote_$(adb shell pidof <package> | tr -d '\r')
WS=$(curl -s http://127.0.0.1:9444/json | jq -r '.[0].webSocketDebuggerUrl')
```

## Evaluate in the page

Any CDP client works. The essentials are `Runtime.evaluate` with
`returnByValue: true, awaitPromise: true`, and `Page.enable` for screenshots and
screencasts. A page reload destroys the execution context but not the socket;
wait for the app to paint again, and re-read `/json` if the target went away.
Reconnecting to an already-open socket hangs, so connect once per process.

## Check what is actually visible

A surface can cover an element while its node still exists, which makes naive
"does the button exist" checks lie. Ask the page what is at the point:

```js
(() => {
  const button = [...document.querySelectorAll('button')]
    .find((b) => (b.getAttribute('aria-label') || '').includes('the label'));
  if (!button) return { found: false };
  const r = button.getBoundingClientRect();
  const hit = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2);
  return { found: true, visible: hit === button || button.contains(hit), x: r.x + r.width / 2, y: r.y + r.height / 2 };
})()
```

When it is not visible, close the covering surface: a close control in the page,
or `adb shell input keyevent 4`.

## Fill fields

React inputs ignore a direct assignment. Use the native setter and dispatch the
event the framework listens for:

```js
const set = (el, value) => {
  Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set.call(el, value);
  el.dispatchEvent(new Event('input', { bubbles: true }));
};
```

Await a short delay after the last field before clicking submit; some forms
validate on a debounce.

## Tap

Prefer the app's own touch path over `el.click()`:

```js
await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y }] });
await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
```

`Input.dispatchTouchEvent` takes CSS pixels inside the page. If you only have a
device coordinate from a screenshot or `uiautomator`, convert with the WebView
rect and `window.innerWidth`: `css = (device - webviewTop) * innerWidth / webviewWidth`.

## Settings and state

Preferences may be read when a view is built rather than reactively. Set the
value through whatever the app persists to (its own settings API or store),
then reload the page so the view rebuilds with it. Setting it afterwards and
watching for a change is a reliable way to waste an hour.
