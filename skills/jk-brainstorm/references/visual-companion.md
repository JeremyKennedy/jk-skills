<!-- Derived from superpowers v5.0.5: visual-companion -->

# Visual Companion Guide

Browser-based visual brainstorming companion for showing mockups, diagrams, and options.

## When to Use

Decide per-question, not per-session. The test: **would the user understand this better by seeing it than reading it?**

**Use the browser** when the content itself is visual:

- **UI mockups** — wireframes, layouts, navigation structures, component designs
- **Architecture diagrams** — system components, data flow, relationship maps
- **Side-by-side visual comparisons** — comparing two layouts, two color schemes, two design directions
- **Design polish** — when the question is about look and feel, spacing, visual hierarchy
- **Spatial relationships** — state machines, flowcharts, entity relationships rendered as diagrams

**Use the terminal** when the content is text or tabular:

- **Requirements and scope questions** — "what does X mean?", "which features are in scope?"
- **Conceptual A/B/C choices** — picking between approaches described in words
- **Tradeoff lists** — pros/cons, comparison tables
- **Technical decisions** — API design, data modeling, architectural approach selection
- **Clarifying questions** — anything where the answer is words, not a visual preference

A question *about* a UI topic is not automatically a visual question. "What kind of wizard do you want?" is conceptual — use the terminal. "Which of these wizard layouts feels right?" is visual — use the browser.

## How It Works

The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content, the user sees it in their browser and can click to select options. Selections are recorded to a `.events` file that you read on your next turn.

**Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, selection indicator, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.

## Starting a Session

```bash
# Start server with persistence (mockups saved to project)
skills/jk-brainstorm/scripts/start-server.sh --project-dir /path/to/project

# Returns: {"type":"server-started","port":52341,"url":"http://localhost:52341",
#           "screen_dir":"/path/to/project/.jk-brainstorm/12345-1706000000"}
```

Save `screen_dir` from the response. Tell user to open the URL.

**Finding connection info:** The server writes its startup JSON to `$SCREEN_DIR/.server-info`. If you launched the server in the background and didn't capture stdout, read that file to get the URL and port.

**Note:** Pass the project root as `--project-dir` so mockups persist in `.jk-brainstorm/` and survive server restarts. Without it, files go to `/tmp` and get cleaned up. Remind the user to add `.jk-brainstorm/` to `.gitignore` if it's not already there.

## The Loop

1. **Check server is alive**, then **write HTML** to a new file in `screen_dir`:
   - Before each write, check that `$SCREEN_DIR/.server-info` exists. If it doesn't (or `.server-stopped` exists), the server has shut down — restart it. The server auto-exits after 30 minutes of inactivity.
   - Use semantic filenames: `platform.html`, `visual-style.html`, `layout.html`
   - **Never reuse filenames** — each screen gets a fresh file
   - Use Write tool — **never use cat/heredoc** (dumps noise into terminal)
   - Server automatically serves the newest file

2. **Tell user what to expect**, then **watch for their interaction:**
   - Remind them of the URL (every step, not just first)
   - Give a brief text summary of what's on screen (e.g., "Showing 3 layout options")
   - Tell them: "Click an option in the browser, or type your thoughts here."
   - **Immediately start watching** the `.events` file for clicks. Do NOT end your turn and wait for terminal input — the user may interact only via the browser. Use a blocking watch command:
     ```bash
     # Watch for browser clicks (timeout after 5 minutes)
     inotifywait -t 300 -e modify "$SCREEN_DIR/.events" 2>/dev/null && cat "$SCREEN_DIR/.events"
     ```
     If `inotifywait` is not available, poll:
     ```bash
     # Poll for .events file changes (check every 2s, timeout 5min)
     for i in $(seq 1 150); do
       if [ -f "$SCREEN_DIR/.events" ] && [ -s "$SCREEN_DIR/.events" ]; then
         cat "$SCREEN_DIR/.events"; exit 0
       fi
       sleep 2
     done
     echo "timeout"
     ```
   - Run this as a **background task** (`run_in_background: true`) so the user can also type in the terminal. Whichever comes first — a browser click or terminal input — drives the next step.

3. **Process the interaction:**
   - If the background watcher triggered, read the `.events` output for click data
   - If the user typed in the terminal, also check `.events` for any browser clicks
   - Merge both sources to get the full picture

4. **Iterate or advance** — if feedback changes current screen, write a new file (e.g., `layout-v2.html`). Only move to the next question when the current step is validated.

5. **Unload when returning to terminal** — when the next step doesn't need the browser, push a waiting screen:

   ```html
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">Continuing in terminal...</p>
   </div>
   ```

6. Repeat until done.

## Writing Content Fragments

Write just the content that goes inside the page. The server wraps it in the frame template automatically.

**Minimal example:**

```html
<h2>Which layout works better?</h2>
<p class="subtitle">Consider readability and visual hierarchy</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Single Column</h3>
      <p>Clean, focused reading experience</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>Two Column</h3>
      <p>Sidebar navigation with main content</p>
    </div>
  </div>
</div>
```

No `<html>`, no CSS, no `<script>` tags needed. The server provides all of that.

## CSS Classes Available

### Options (A/B/C choices)
```html
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content"><h3>Title</h3><p>Description</p></div>
  </div>
</div>
```

**Multi-select:** Add `data-multiselect` to the container.

### Cards (visual designs)
```html
<div class="cards">
  <div class="card" data-choice="design1" onclick="toggleSelect(this)">
    <div class="card-image"><!-- mockup content --></div>
    <div class="card-body"><h3>Name</h3><p>Description</p></div>
  </div>
</div>
```

### Mockup container
```html
<div class="mockup">
  <div class="mockup-header">Preview: Dashboard Layout</div>
  <div class="mockup-body"><!-- your mockup HTML --></div>
</div>
```

### Split view, Pros/Cons, Mock elements
```html
<div class="split"><!-- two side-by-side mockups --></div>
<div class="pros-cons">
  <div class="pros"><h4>Pros</h4><ul><li>...</li></ul></div>
  <div class="cons"><h4>Cons</h4><ul><li>...</li></ul></div>
</div>
<div class="mock-nav">Logo | Home | About</div>
<button class="mock-button">Action</button>
<input class="mock-input" placeholder="Input field">
<div class="placeholder">Placeholder area</div>
```

### Typography
- `h2` — page title
- `h3` — section heading
- `.subtitle` — secondary text
- `.section` — content block with margin
- `.label` — small uppercase label

## Browser Events Format

Interactions recorded to `$SCREEN_DIR/.events` (one JSON object per line, cleared on new screen):

```jsonl
{"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
{"type":"click","choice":"b","text":"Option B - Hybrid","timestamp":1706000115}
```

The last `choice` event is typically the final selection. If `.events` doesn't exist, the user didn't interact with the browser.

## Cleaning Up

```bash
skills/jk-brainstorm/scripts/stop-server.sh $SCREEN_DIR
```

Persistent directories (`.jk-brainstorm/`) are kept. Only `/tmp` sessions get deleted on stop.
