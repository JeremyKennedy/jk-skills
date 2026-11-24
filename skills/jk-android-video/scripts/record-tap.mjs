#!/usr/bin/env node
// Record an Android app's screen with the tap visible, then encode an MP4.
//
// Why this exists instead of `adb shell screenrecord`:
//
// - On a headless emulator screenrecord finalizes after about two seconds, so
//   the clip ends before the thing you are recording happens.
// - Android's `show_touches` overlay is drawn by the system, outside the app's
//   compositor, so a WebView screencast does not carry it either.
//
// This drives the app through its WebView DevTools socket, paints a tap marker
// at the exact point the touch is dispatched, and keeps each frame for as long
// as it was on screen. The marker marks a real touch: the event is sent as a
// touch at those coordinates, not synthesised in the page.
//
// Usage:
//   node record-tap.mjs --ws <devtools ws url> --out clip.mp4 \
//     --tap "<js expression returning {x,y} in CSS pixels>" [--pre 1400] [--post 6000]
//   node record-tap.mjs --ws <url> --out clip.mp4 --x 175 --y 900
//
// The tap expression runs in the page and must resolve to {x, y} CSS pixels;
// it can also return {x, y, waitFor: '<regex source>'} to keep recording until
// that text appears (useful when a file or page takes a moment to paint).
//
// Requires Node 22+ (global WebSocket) or Bun. ffmpeg on PATH.

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const args = process.argv.slice(2);
const arg = (name, fallback = null) => {
  const i = args.indexOf(`--${name}`);
  return i === -1 ? fallback : (args[i + 1] ?? fallback);
};

const wsUrl = arg('ws');
const out = arg('out', 'clip.mp4');
const tapExpr = arg('tap');
const fixedX = arg('x');
const fixedY = arg('y');
const pre = Number(arg('pre', '1400'));
const post = Number(arg('post', '6000'));
const maxWidth = Number(arg('width', '480'));
const maxHeight = Number(arg('height', '1000'));

if (!wsUrl || (!tapExpr && (!fixedX || !fixedY))) {
  console.error('usage: record-tap.mjs --ws <url> --out clip.mp4 (--tap "expr" | --x N --y N) [--pre ms] [--post ms]');
  process.exit(2);
}

class Cdp {
  constructor(url) {
    this.url = url;
    this.nextId = 1;
    this.pending = new Map();
    this.listeners = new Map();
  }
  async connect() {
    this.socket = new WebSocket(this.url);
    await new Promise((resolve, reject) => {
      this.socket.addEventListener('open', resolve, { once: true });
      this.socket.addEventListener('error', reject, { once: true });
    });
    this.socket.addEventListener('close', () => {
      for (const [, pending] of this.pending) pending.reject(new Error('CDP closed'));
      this.pending.clear();
    });
    this.socket.addEventListener('message', (event) => {
      const message = JSON.parse(String(event.data));
      if (message.id) {
        const pending = this.pending.get(message.id);
        if (!pending) return;
        this.pending.delete(message.id);
        if (message.error) pending.reject(new Error(message.error.message));
        else pending.resolve(message.result ?? {});
        return;
      }
      for (const listener of this.listeners.get(message.method) ?? []) listener(message.params ?? {});
    });
  }
  send(method, params = {}) {
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }
  on(method, listener) {
    const set = this.listeners.get(method) ?? new Set();
    set.add(listener);
    this.listeners.set(method, set);
  }
  close() { this.socket.close(); }
}

const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const evaluate = async (client, expression) => {
  const result = await client.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  return result.result?.value ?? null;
};

const client = new Cdp();
await client.connect();
await client.send('Page.enable');
await client.send('Runtime.enable');

const target = tapExpr
  ? await evaluate(client, tapExpr)
  : { x: Number(fixedX), y: Number(fixedY) };
if (!target || typeof target.x !== 'number' || typeof target.y !== 'number') {
  throw new Error(`tap target did not resolve to {x, y}: ${JSON.stringify(target)}`);
}
console.log('tap at', target);

const framesDir = fs.mkdtempSync(path.join(os.tmpdir(), 'android-clip-'));
const shots = [];
let capturing = true;
let index = 0;
const writes = [];
client.on('Page.screencastFrame', ({ data, sessionId }) => {
  if (!capturing) return;
  const file = path.join(framesDir, `f-${String(index).padStart(4, '0')}.png`);
  index += 1;
  shots.push({ file, at: Date.now() });
  writes.push(fs.promises.writeFile(file, Buffer.from(data, 'base64')));
  client.send('Page.screencastFrameAck', { sessionId }).catch(() => {});
});

await client.send('Page.startScreencast', { format: 'png', everyNthFrame: 1, maxWidth, maxHeight });
await wait(pre);

// The marker marks the point the touch lands on. The style is created once so
// the marker can animate without a second frame of setup.
await evaluate(client, `(() => {
  if (!document.getElementById('tap-marker-style')) {
    const style = document.createElement('style');
    style.id = 'tap-marker-style';
    style.textContent = '@keyframes tap-marker { from { transform: scale(.6); opacity: .9 } to { transform: scale(1.4); opacity: 0 } }';
    document.head.appendChild(style);
  }
  const dot = document.createElement('div');
  dot.id = 'tap-marker';
  dot.style.cssText = 'position:fixed;left:${target.x}px;top:${target.y}px;width:44px;height:44px;'
    + 'margin:-22px 0 0 -22px;border-radius:50%;border:2px solid rgba(20,20,20,.6);'
    + 'background:rgba(110,160,255,.5);box-shadow:0 0 0 6px rgba(110,160,255,.18);'
    + 'pointer-events:none;z-index:2147483647';
  document.body.appendChild(dot);
  return true;
})()`);
await wait(320);
await evaluate(client, `(document.getElementById('tap-marker').style.animation = 'tap-marker .6s ease-out forwards', true)`);

await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: target.x, y: target.y }] });
await wait(90);
await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
await wait(180);
await evaluate(client, `document.getElementById('tap-marker')?.remove(); true`);

if (target.waitFor) {
  const pattern = new RegExp(target.waitFor, 'i');
  for (let i = 0; i < Math.ceil(post / 300); i += 1) {
    await wait(300);
    const seen = await evaluate(client, `(${pattern.toString()}).test(document.body.innerText)`).catch(() => false);
    if (seen) break;
  }
  await wait(700);
} else {
  await wait(post);
}

capturing = false;
await client.send('Page.stopScreencast');
await Promise.allSettled(writes);
client.close();

if (shots.length === 0) throw new Error('no frames captured; is the WebView on screen?');

// Frames arrive on damage, so each one stays until the next arrives.
const lines = [];
for (let i = 0; i < shots.length; i += 1) {
  const next = shots[i + 1]?.at ?? shots[i].at + 1200;
  lines.push(`file '${shots[i].file}'`, `duration ${Math.max(0.08, (next - shots[i].at) / 1000).toFixed(3)}`);
}
lines.push(`file '${shots[shots.length - 1].file}'`);
const concat = path.join(framesDir, 'concat.txt');
fs.writeFileSync(concat, lines.join('\n'));

const encoded = spawnSync('ffmpeg', [
  '-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', concat,
  '-vf', 'fps=12,scale=trunc(iw/2)*2:trunc(ih/2)*2', '-pix_fmt', 'yuv420p', out,
], { encoding: 'utf8' });
if (encoded.status !== 0) throw new Error(`ffmpeg failed: ${encoded.stderr.slice(0, 400)}`);

console.log(`frames: ${shots.length}`);
console.log(`video: ${out}`);
console.log('Verify it: extract the first, middle and last frames and look at them, and check the content you expected is painted in the last one.');
