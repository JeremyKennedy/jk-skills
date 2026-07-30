---
name: jk-converse
description: Set up a structured async conversation between two or more agents via a shared JSONL file and the converse script — automatic turn detection, convergence protocol, persistent record
---

# Converse

Structured async conversation between two or more agent sessions over a shared
JSONL file, driven by the `converse` script. One agent initiates, the others
respond, the user bridges the sessions. The script handles message delivery,
"what's new since you last looked," and waiting — so agents never miscount
offsets or forget to wait.

## The Script

A single self-contained Python script (stdlib only, no dependencies) lives
alongside this skill. Resolve it to an absolute path once:

```
<skill-directory>/scripts/converse.py
```

Invoke it as `python3 /abs/path/to/converse.py <command> ...`.

Each conversation is one JSONL file. The script tracks, per participant, which
messages they have already seen — so any participant can ask "what's new?" and
get exactly the messages they haven't read yet, from anyone but themselves.

### Commands

| Command | What it does |
|---------|--------------|
| `init <file> --topic T --context C [--participants a,b]` | Create the conversation. Writes topic + context as the first record. |
| `post <file> --as NAME [--to A,B] [-m MSG \| -f FILE \| stdin] [--wait]` | Append your message, then print any messages addressed to you that arrived since you last looked. `--to` narrows recipients (default: broadcast). With `--wait`, immediately block for the next reply. |
| `wait <file> --as NAME [--timeout N]` | Block until a new message arrives, then print it. Returns immediately if one is already waiting. |
| `read <file> --as NAME [--peek]` | Print new messages without posting. `--peek` leaves them unread. |
| `last <file> --from NAME [--as VIEWER] [--body]` | Print the most recent message from a specific agent (does not touch read cursors). |
| `digest <file> [--each N] [--as VIEWER] [--full]` | Last N messages from each agent (default 1), grouped by agent, most-recently-active first. Compact one-liners unless `--full`. Read-only. |
| `join <file> --as NAME [--digest N]` | Catch NAME up to now: set their cursor to the latest message so they receive no backlog, only messages posted afterward. `--digest N` prints the last N per agent first as a primer. |
| `log <file> [--as VIEWER]` | Render the full transcript as readable markdown. |

Key behaviors:

- **`post` always reports new messages.** After appending, it tells you what the other agent said while you were composing. If nothing is new, it says so.
- **`wait` never blocks on a message that already arrived.** It checks first, and only sleeps if there is genuinely nothing new.
- **`wait` without `--timeout` waits indefinitely.** With `--timeout N` it exits with status `2` after N seconds.
- Bodies may be passed with `-m`, read from a file with `-f PATH`, or piped on stdin.
- **Messages broadcast to everyone by default.** `--to a,b` sends a directed message that only those agents (and the sender) can see. Prefer broadcasting; narrow only when the info genuinely needn't be shared.

> **Do not chain `read … && wait …`.** `read` marks the backlog seen and advances your cursor, so the following `wait` has nothing pending and blocks — you've drained messages you should be responding to and then sat idle. The loop is **`wait` → act → `post --wait` → act → …**, never drain-then-block.

## Roles

### You (the initiating agent)

1. Resolve the script path and pick conversation + participant names.
2. `init` the conversation file with topic and context.
3. `post` your opening position.
4. Give the user a copy-pasteable handoff block for the other session.
5. `wait` for the response (this is your turn-ending action).
6. Read, `post` your reply, `wait` again. Repeat until convergence.

### The user

Bridges the sessions. They paste your handoff block into the other agent's session. They do not mediate content.

### The other agent

In a separate session, without this skill loaded. It gets everything it needs from the handoff block: the script path, the file path, its participant name, and the command patterns.

## Step 1: Initialize

Choose an absolute path for the conversation file and names for participants (e.g. `agent-1` / `agent-2`, or descriptive roles). Put enough in `--context` that the other agent can participate cold — it has not seen your conversation history.

```bash
python3 /abs/path/converse.py init /abs/conversation.jsonl \
  --topic "Scope of the widget refactor" \
  --context "Deciding whether to extract WidgetStore. Key files: src/widget/*. The user wants minimal surface area." \
  --participants agent-1,agent-2
```

## Step 2: Post Your Opening

```bash
python3 /abs/path/converse.py post /abs/conversation.jsonl --as agent-1 \
  -m "I propose extracting WidgetStore. Two questions: (1) keep the existing name? (2) move the cache too?"
```

For longer openings, pipe on stdin:

```bash
python3 /abs/path/converse.py post /abs/conversation.jsonl --as agent-1 -f - <<'EOF'
My analysis ...
multiple paragraphs ...
EOF
```

## Step 3: Give the User the Handoff Block

Give the user a single copy-pasteable block for the other session. Fill in the real absolute paths and names.

````
Paste this into the other agent session:

```
You are joining an async agent conversation driven by a script. You are "agent-2".

The conversation file: /abs/conversation.jsonl
The script:           python3 /abs/path/converse.py

1. See what's been said:
     python3 /abs/path/converse.py read /abs/conversation.jsonl --as agent-2

2. Post your response (it will also report anything new since you looked):
     python3 /abs/path/converse.py post /abs/conversation.jsonl --as agent-2 -f - <<'EOF'
     <your response>
     EOF

3. Wait for the reply — ALWAYS end your turn with this:
     python3 /abs/path/converse.py wait /abs/conversation.jsonl --as agent-2
   When it returns, it prints the new message(s); read them, then post your reply and wait again.

Protocol:
- State positions explicitly: "I agree with X" / "I disagree because Y".
- Number your points when responding to multiple items.
- End with specific questions or a clear ask.

Convergence: iterate until you agree. When satisfied, post a message that ends
with "I confirm this exact scope:" followed by a numbered list. I will do the
same. Stop after mutual confirmation.
```
````

## Turn Loop

Use `post --wait` so each turn is one call — say your piece, then listen for the reply:

```
1. (act on the messages you just received)
2. post --wait  your reply      (appends, then blocks for the next message)
3. read the printed reply, go to 1
```

To enter the loop, start with a bare `wait` — it returns the current backlog immediately if there is one, otherwise blocks for the next message.

## Convergence

Conversations must converge with explicit scope confirmation. The pattern:

1. **Opening**: State your position, ask specific questions.
2. **Response**: Answer each question directly, raise new concerns.
3. **Synthesis**: Propose a unified position, enumerate exact scope.
4. **Confirmation**: Both agents post a message ending with "I confirm this exact scope:" followed by a numbered list. Stop when all participants have confirmed.

Most conversations converge in 2–4 rounds. If you're past 4 rounds without agreement, stop waiting and escalate to the user.

## Conversation Quality

- **Be specific, not diplomatic.** "I disagree because X" not "perhaps we could consider..."
- **Push back on over-engineering.** If the other agent proposes unnecessary complexity, say so.
- **Ground arguments in the codebase.** Reference file paths, line numbers, existing patterns.
- **Respect the user's stated preferences.** If the user already rejected an approach, don't re-propose it.
- **Reject false consensus.** Agreeing to avoid conflict wastes time. If you disagree, say why and propose an alternative.

## More Than Two Agents

Pass more than two to `--participants` and hand each additional session its own handoff block. Every participant's "what's new" is tracked independently. For a panel, designate one participant to call convergence once all have confirmed.

For a **parent/worker hierarchy**, workers can broadcast shared findings to all but report routine status with `--to parent` so they don't spam siblings. Default to broadcasting; reach for `--to` only when the information genuinely doesn't need sharing.

**Onboarding a new agent into a long thread:** have it `join` rather than `read`/`wait` first — otherwise its first call returns the entire backlog. A silent `join --as agent-N` starts it caught-up (future messages only); add `--digest 2` for a quick primer.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Ending your turn without `wait` | Make `wait` the final action of every turn until convergence. |
| Re-reading the whole file to find "what's new" | `post`/`read`/`wait` already print exactly what you haven't seen. |
| Hardcoding a wrong script path | Resolve `<skill-directory>/scripts/converse.py` to an absolute path once, reuse it. |
| Handoff block missing the script or file path | The other agent has no skill loaded — give it the full command patterns. |
| Messages too long and unfocused | Lead with your position, then supporting evidence. |
| No explicit questions at the end | Every message should drive toward a decision. |
| Agreeing too easily to avoid conflict | If you disagree, say why. False consensus wastes time. |
| No explicit confirmation of final scope | End with a numbered list all agents confirm verbatim. |
