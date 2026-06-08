---
name: jk-code-review
description: Use when completing tasks, implementing major features, reviewing code changes, or before merging
---
<!-- Derived from superpowers v4.2.0: requesting-code-review -->

# Code Review

**Announce at start:** "I'm using the jk-code-review skill to dispatch a code review."

Dispatch themed reviewer subagents to catch issues before they cascade. This is the canonical review dispatch — jk-execute invokes this skill for per-task code quality reviews.

**Core principle:** Review early, review often, and review by explicit themes. A generic "review this" prompt is not enough for nontrivial diffs.

## When to Request Review

**Automatic (via jk-execute):**
- Per-task code quality review during Deep/Swarm/Care execution

**Manual:**
- After completing a major feature or bugfix
- Before merge to main
- When asked to review a PR, diff, branch, implementation plan, or proposed patch

**Optional but valuable:**
- When stuck and needing a fresh perspective
- Before refactoring, to establish current risks
- After fixing a complex bug, to verify the reasoning and regressions

## Review Depth

Choose depth based on diff risk, not file count alone.

### Tiny diff fast path

Use one reviewer when the change is trivial and low risk: typo fixes, comments, small docs edits, mechanical formatting, or one-line code changes with obvious behavior.

The single reviewer must still consider the themes below and say which were relevant.

### Nontrivial diff default

For meaningful behavior changes, feature work, bug fixes, refactors, API changes, security-sensitive edits, data/model changes, concurrency/background work, or anything the user explicitly cares about: **dispatch parallel themed reviewers**.

Do not ask one subagent to "just review this". Theme separation catches different classes of mistakes and prevents structural/style review from crowding out reasoning.

## Theme Matrix

Launch one fresh-context reviewer per relevant theme. For substantial diffs, default to all core themes plus one free theme.

| Theme | What to review |
|---|---|
| **Correctness / reasoning / logic** | Does the behavior make sense? Are invariants preserved? Are conditionals, error paths, state transitions, data transformations, and failure classifications logically correct? Look for too-broad catches, false positives/negatives, misleading results, and edge cases. |
| **Simplicity / maintainability** | Is this the smallest coherent change? Is complexity justified? Are names, boundaries, abstractions, and coupling understandable? Is there duplicated or dead code? |
| **Tests / validation** | Do tests prove the intended behavior and negative cases? Do they fail for the right reason? Are they too mocked or too implementation-specific? Which commands were run or still need running? |
| **Performance / operations** | Any runtime, memory, I/O, concurrency, background-job, retry, timeout, deployment, migration, or observability impact? Any unbounded loops/scans or expensive work in hot paths? |
| **Security / privacy** | Secrets, unsafe input handling, auth/permission changes, injection, data exposure, sensitive logging, dependency/supply-chain risk, unsafe defaults. Keep this generic; project-specific policies belong in project skills/docs. |
| **Integration / compatibility** | API/CLI contracts, schema/data compatibility, migrations, versioning, config/env behavior, backwards compatibility, cross-module assumptions, external-system behavior. |
| **Docs / user-facing clarity** | Do docs, comments, PR text, changelogs, help text, and user-facing messages match the change? Are misleading names or stale explanations introduced? |
| **Free theme** | The orchestrator chooses one additional risk-specific lens based on the diff: examples include accessibility/UX, data integrity, numerical correctness, concurrency races, migration rollback, platform portability, developer experience, or domain-specific semantics. |

## How to Request

### 1. Identify the review target

Get the base and head SHAs or equivalent diff target:

```bash
BASE_SHA=$(git rev-parse origin/main)  # or plan/base commit
HEAD_SHA=$(git rev-parse HEAD)
```

Capture what was intended:

- Requirements, issue, PR body, or implementation plan
- What changed and why
- Expected validation commands
- Any project-specific review rules already loaded

### 2. Dispatch themed reviewer subagents

For nontrivial diffs, launch parallel fresh-context reviewers. Use the local agent name supported by the harness (`reviewer`, `code-reviewer`, or equivalent). Each reviewer gets one theme, the target range, requirements, and strict review-only constraints.

Generic prompt shape (or fill `references/code-reviewer.md`):

```text
Review theme: <THEME>

Target: <what changed>
Requirements: <plan/PR/user request>
Git range: <BASE_SHA>..<HEAD_SHA>

Inspect the diff directly. Focus only on your theme. Report evidence-backed findings with file:line references. Do not edit files. If your theme has no findings, say so and explain what you checked.

Severity definitions:
- Critical: data loss, security issue, broken core behavior, unrecoverable deploy/runtime risk
- Important: likely bug, misleading behavior, missing required case, inadequate validation, significant maintainability risk
- Minor: cleanup, clarity, small robustness improvement

Return: findings by severity, notable strengths for this theme, recommendations, then theme coverage notes.
```

Template placeholders:
- `{THEME}` - assigned review theme
- `{WHAT_WAS_IMPLEMENTED}` - what changed
- `{PLAN_OR_REQUIREMENTS}` / `{PLAN_REFERENCE}` - what it should do
- `{BASE_SHA}` - starting commit/base
- `{HEAD_SHA}` - ending commit/head
- `{DESCRIPTION}` - brief implementation summary

### 3. Synthesize severity-first

The parent/orchestrator owns synthesis. Do not paste every reviewer transcript verbatim.

Final report shape:

1. **Findings first, ordered by severity** across all themes.
2. **Open questions / assumptions**.
3. **Notable strengths** when they help calibrate the review.
4. **Brief summary** of the change and overall readiness.
5. **Theme coverage checklist** showing which themes were reviewed and the conclusion for each.
6. **Verification**: commands run, commands not run, and any failures.

### 4. Act on feedback

- Fix Critical issues immediately.
- Fix Important issues before proceeding unless the user explicitly defers them.
- Note Minor issues for later when they are not worth blocking.
- Push back if a reviewer is wrong, with technical reasoning and evidence.

## Example

```
[Just completed Task 2: Add retry handling]

BASE_SHA=$(git rev-parse origin/main)
HEAD_SHA=$(git rev-parse HEAD)

Dispatch reviewers:
- Correctness / reasoning: retry state transitions, error classification, edge cases
- Tests / validation: test coverage and command evidence
- Performance / operations: retry delays, hot paths, observability
- Security / privacy: sensitive logging and unsafe defaults
- Simplicity / maintainability: unnecessary abstractions or coupling
- Integration / compatibility: API/config/backwards compatibility
- Docs / clarity: help text and comments
- Free theme: concurrency races (chosen because retry state is shared)

Synthesize:
Critical: none
Important: retry swallows cancellation errors at retry.ts:88
Minor: docs omit retry limit default
Theme coverage: ...
Verification: ...
```

## Integration

**jk-execute** invokes this skill automatically for per-task code quality reviews. You do NOT need to separately invoke jk-code-review during jk-execute unless you want an extra review pass.

**Ad-hoc development:** Invoke this skill manually whenever you want a code review outside of jk-execute.

**Project-specific reviews:** Generic themes belong here. Project-specific policies, forbidden APIs, deployment rules, privacy commitments, or PR transport requirements belong in the project instructions or project-specific review skills.

## Red Flags

**Never:**
- Skip review because "it's simple" when the diff is behaviorally meaningful.
- Use only one generic "review this" subagent for a nontrivial diff.
- Let formatting/style findings crowd out reasoning and logic.
- Ignore Critical issues.
- Proceed with unfixed Important issues without explicit user deferral.
- Argue with valid technical feedback.

**If reviewer wrong:**
- Push back with technical reasoning.
- Show code/tests that prove it works.
- Request clarification when evidence is ambiguous.

See template at: `jk-code-review/references/code-reviewer.md`
