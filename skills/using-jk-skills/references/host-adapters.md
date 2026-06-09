# Host adapters

Use this reference when a skill names tools, subagents, models, plan UI, or memory in a host-specific way.

## Tool names

| Need | Claude Code | Pi | OpenCode / other hosts |
|---|---|---|---|
| Load a skill | `Skill` tool | read/injected skill file | native `skill` tool if present; otherwise read the skill file |
| Track tasks | `TodoWrite` / task list | `todo` | `todowrite` or native task tool |
| Ask structured questions | `AskUserQuestion` | `ask_user_question` | `question` or direct chat |
| Delegate subagents | `Task` | `subagent` | native agent/delegate tool |
| Present plan for approval | `EnterPlanMode` / `ExitPlanMode` | `ask_user_question` or chat approval | native plan/approval UI or chat |
| Persist memory | Claude memory / instructions | context-mode memory, docs, or instructions | host memory if available, else docs/instructions |

If the named host tool does not exist, use the closest native equivalent and say which adaptation you made.

## Model tiers

Skill text uses capability tiers, not provider-specific names:

| Tier | Use for | Default guidance |
|---|---|---|
| Mechanical | Formatting, file lists, trivial boilerplate with no judgment | cheapest enabled model that cannot hurt quality |
| Focused | Exploration, focused review, clear criteria | host default unless the user set a cheaper focused model |
| Deep | Ambiguous design, implementation, root-cause analysis | host default or explicit deep model |

Host-specific model policies:

- Claude Code: use the user's selected/default model unless the user asks for a specific model family.
- Pi: use `openai-codex/gpt-5.5` by default for reasoning/review/oracle/worker subagents; use `deepseek/deepseek-v4-flash` only for purely mechanical tasks with no real reasoning; use `deepseek/deepseek-v4-pro` only when the user explicitly asks for it in the current task/session.
- OpenCode: use the configured default model unless the user asks for a specific provider/model.

Rules:

- Prefer the host default model when unsure.
- Never hardcode Claude aliases (`haiku`, `sonnet`, `opus`) or Anthropic model IDs unless that provider is configured.
- Inspect the active host settings or available models before overriding a model.
- A failed or unwanted model override is worse than no override.

## Subagent runtime

- Productive subagents should normally run asynchronously when the host supports it.
- A timeout is a kill/interrupt budget, not a progress signal. Avoid foreground `timeoutMs` for productive work.
- Use status/control/attention mechanisms to detect stalls. Interrupt only when the agent is actually blocked or drifting.
- If foreground execution is required, choose a generous timeout larger than the expected work and validation window.
- Short timeouts are only for mechanical probes where killing the process loses no useful reasoning or edits.
