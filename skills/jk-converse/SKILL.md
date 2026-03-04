---
name: jk-converse
description: "Set up a structured async conversation between two agents via a shared markdown file — inotifywait-based turn detection, convergence protocol, persistent record"
---

# Converse

**Announce at start:** "I'm using the jk-converse skill to set up a structured conversation with another agent."

Structured async conversation between two Claude Code sessions via a shared markdown file. One agent initiates, the other responds, the user bridges them.

## Roles

There are exactly three participants. Each has a clear contract.

### You (the initiating agent)

You invoked this skill. Your job:

1. **Create the conversation file** with context and your opening position
2. **Start `inotifywait`** to watch the file for the other agent's response
3. **Read and respond** when the file changes
4. **Repeat** until convergence
5. **Tell the user** the file path and what to paste into the other session

You own the file. You write first. You watch for changes.

### The user

The user bridges the two sessions. Their job:

1. Go to the other Claude Code session
2. Paste the instructions you give them (file path + protocol)
3. That's it — they don't mediate content, just connect the sessions

Give the user a **copy-pasteable block** they can drop into the other session. Don't make them explain the protocol themselves.

### The other agent

The other agent is in a separate Claude Code session. It does NOT have this skill loaded. It gets its instructions from the copy-pasteable block the user pastes in. Its job:

1. Read the conversation file
2. Append a response following the message format
3. Watch for your response via `inotifywait`
4. Repeat until convergence

## Step 1: Create the Conversation File

```markdown
# Agent Conversation: <Topic>

<Context paragraph — what's being discussed, what's already known, key files>

---

## Agent-1: Opening position

<Your analysis, proposed approach, specific questions for the other agent>
```

Place in the project root or `/tmp/`. Include enough context that the other agent can participate cold — it hasn't seen your conversation history.

## Step 2: Give the User the Handoff Block

After creating the file and writing your opening, give the user a single copy-pasteable block for the other session. It must include:

1. The absolute file path
2. The message format rules
3. Instructions to watch for responses

Example — adapt this to your actual file path and topic:

````
Paste this into the other Claude Code session:

```
Read /absolute/path/to/conversation.md — it contains a conversation about <topic>.

Your role: you are Agent-2. Read the conversation so far, then append your response to the file.

Message format — append this structure:

---

## Agent-2: <Brief topic>

<Your response — analysis, agreements, disagreements>

<Specific questions or confirmation at the end>

Rules:
- --- delimiter before your message
- ## Agent-2: header with a brief subject
- End with questions or a clear ask
- State positions explicitly: "I agree with X" or "I disagree because Y"
- Number your points when responding to multiple items

After writing your response, watch for mine:
inotifywait -e modify /absolute/path/to/conversation.md
Run that with run_in_background: true. When notified, read the new content and respond.

Convergence: we iterate until we reach agreement. When you're satisfied, write "I confirm this exact scope:" followed by a numbered list. I'll do the same. Stop after mutual confirmation.
```
````

This is the contract. The other agent gets everything it needs from this block — no skill loading required.

## Step 3: Watch for Responses

After the user confirms they've pasted the handoff block, start watching:

```bash
inotifywait -e modify /path/to/conversation.md
```

Run this with `run_in_background: true`. When notified, read the new content (use offset to skip what you already read) and append your response.

## Turn Loop

```
1. Write your message (append to file)
2. Start inotifywait in background
3. Wait for notification
4. Read the new content (offset past what you've already seen)
5. Write your response
6. Repeat from step 2
```

The critical mistake is **not waiting**. If you write your message and immediately try to continue without `inotifywait`, you'll miss the response entirely.

## Message Format

Each message appended to the file:

```markdown
---

## Agent-N: <Brief topic>

<Response body — analysis, agreements, disagreements>

<Specific questions or confirmation request at the end>
```

Rules:
- **`---` delimiter** before each new message
- **`## Agent-N: Topic` header** — identifies speaker and subject
- **End with questions or a clear ask** — drives the conversation forward
- **State positions explicitly** — "I agree with X" or "I disagree because Y"
- **Number your points** when responding to multiple questions

## Convergence

Conversations must converge. The pattern:

1. **Opening**: State your position, ask specific questions
2. **Response**: Answer each question directly, raise new concerns
3. **Synthesis**: Propose a unified position, enumerate exact scope
4. **Confirmation**: Both agents write "I confirm this exact scope:" followed by a numbered list

Stop when both agents have confirmed. Don't iterate after agreement.

Most conversations converge in 2-4 rounds. If you're past 4 rounds without agreement, escalate to the user.

## Conversation Quality

- **Be specific, not diplomatic.** "I disagree because X" not "That's an interesting point, perhaps we could consider..."
- **Push back on over-engineering.** If the other agent proposes unnecessary complexity, say so.
- **Ground arguments in the codebase.** Reference file paths, line numbers, existing patterns.
- **Respect the user's stated preferences.** If the user already rejected an approach, don't re-propose it.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Not waiting for response (no `inotifywait`) | Always watch the file before expecting a reply |
| Handoff block missing file path or format rules | Other agent can't participate without the full contract |
| Messages too long and unfocused | Lead with your position, then supporting evidence |
| No explicit questions at the end | Every message should drive toward a decision |
| Agreeing too easily to avoid conflict | If you disagree, say why. False consensus wastes time. |
| No explicit confirmation of final scope | End with numbered list both agents confirm verbatim |
