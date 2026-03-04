---
name: jk-converse
description: Use when two or more agents need to collaborate on a design, diagnosis, or decision through structured asynchronous conversation via a shared file
---

# Inter-Agent Conversation

**Announce at start:** "I'm using the jk-converse skill to set up a structured conversation with another agent."

Structured async conversation between agents via a shared markdown file. Each agent appends messages, uses `inotifywait` to detect responses, and iterates until consensus.

## When to Use

- Two agents have conflicting or complementary analyses that need synthesis
- A design decision benefits from adversarial review by a separate agent
- You need a persistent record of multi-agent reasoning and decisions
- The user explicitly asks agents to "talk to each other" or "work it out"

## When NOT to Use

- One agent can handle the task alone
- The question is simple enough for a single AskUserQuestion
- You just need to delegate work (use Agent tool directly)

## Setup

### 1. Create the conversation file

```markdown
# Agent Conversation: <Topic>

<Context paragraph — what's being discussed, what's already known, key files>

---

## Agent-1: Opening position

<Your analysis, proposed approach, specific questions for the other agent>
```

Place in the project root or a temp location. Include enough context that the other agent can participate without re-reading the entire conversation history.

### 2. Watch for responses

```bash
inotifywait -e modify /path/to/conversation.md
```

Run this in the background (`run_in_background: true`). You'll be notified when the file changes. Then read the new content and append your response.

### 3. Tell the user to point the other agent at the file

The user is the bridge — they tell the other agent where to find the conversation file and to append their response.

## Message Format

Each message follows this structure:

```markdown
---

## Agent-N: <Brief topic>

<Response body — analysis, agreements, disagreements>

<Specific questions or confirmation request at the end>
```

Rules:
- **`---` delimiter** before each new message — makes turns visually distinct
- **`## Agent-N: Topic` header** — identifies speaker and subject
- **End with questions or a clear ask** — drives the conversation forward
- **State positions explicitly** — "I agree with X" or "I disagree because Y"
- **Number your points** when responding to multiple questions — makes it easy to reference

## Convergence Protocol

Conversations must converge. Follow this pattern:

1. **Opening**: State your position, ask specific questions
2. **Response**: Answer each question directly, raise new concerns
3. **Synthesis**: Propose a unified position, enumerate exact scope
4. **Confirmation**: Both agents explicitly confirm the final scope ("I confirm this exact set")

Stop when both agents have explicitly confirmed. Don't keep iterating after agreement.

## Listening for Responses

This is where agents commonly fail. The pattern:

```
1. Write your message (append to file)
2. Start inotifywait in background
3. Wait for notification
4. Read the new content (use offset to skip what you already read)
5. Write your response
6. Repeat from step 2
```

The critical mistake is **not waiting for the other agent's response**. If you write your message and immediately try to continue without `inotifywait`, you'll miss the response entirely.

## Keeping It Productive

- **Be specific, not diplomatic.** "I disagree because X" is better than "That's an interesting point, perhaps we could consider..."
- **Push back on over-engineering.** If the other agent proposes unnecessary complexity, say so with reasoning.
- **Ground arguments in the codebase.** Reference file paths, line numbers, existing patterns.
- **Respect the user's stated preferences.** If the user already rejected an approach, don't re-propose it.
- **Limit rounds.** Most conversations should converge in 2-4 rounds. If you're past 4 rounds without agreement, escalate to the user.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Not waiting for response (no `inotifywait`) | Always watch the file before expecting a reply |
| Messages too long and unfocused | Lead with your position, then supporting evidence |
| No explicit questions at the end | Every message should drive toward a decision |
| Agreeing too easily to avoid conflict | If you disagree, say why. False consensus wastes time. |
| Stale context block at top of file | The conversation IS the context. Don't maintain a separate summary. |
| No explicit confirmation of final scope | End with numbered list both agents confirm verbatim |
