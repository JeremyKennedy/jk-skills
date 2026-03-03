---
name: jk-finish-branch
description: Use when implementation is complete and you need to decide how to integrate — analyzes branch state, presents structured options for merge, PR, push, or cleanup
---
<!-- Derived from superpowers v4.2.0: finishing-a-development-branch -->

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests -> Present options -> Execute choice -> Clean up.

**Default workflow:** Direct push to main. PRs are the exception, not the rule.

**Announce at start:** "I'm using the jk-finish-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Analyze Branch State

Understand the branch before presenting options. Don't assume every branch merges to main.

```bash
# What branch are we on?
CURRENT=$(git branch --show-current)

# How old is this branch? How many commits ahead/behind?
git log --oneline main..$CURRENT 2>/dev/null | wc -l
git log --oneline $CURRENT..main 2>/dev/null | wc -l

# Is there an upstream tracking branch?
git rev-parse --abbrev-ref @{upstream} 2>/dev/null

# Any open PRs for this branch?
gh pr list --head $CURRENT --state open 2>/dev/null
```

**Determine branch type:**

| Signal | Branch type | Default action |
|--------|------------|----------------|
| Branch name is `main`/`master`/`dev` | Trunk development | Push directly |
| Branch has upstream tracking, many commits, old history | Long-lived branch | Push to remote, do NOT suggest merge |
| Branch is recent, few commits, no upstream | Feature branch | Offer merge options |
| Open PR exists | PR branch | Push and update PR |

**For long-lived branches:** Skip merge options. The right action is pushing to the remote branch, not merging to main. Present only options 2-4 (no merge).

### Step 3: Determine Base Branch (Feature Branches Only)

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Present Options

If already on main (direct development), skip to pushing. Otherwise present options based on branch type:

```
Implementation complete. What would you like to do?

1. Merge to <base-branch> and push (default — direct integration)
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option? (default: 1)
```

**Don't add explanation** - keep options concise.

### Step 5: Execute Choice

#### Option 1: Merge and Push (Default)

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# If tests pass
git push
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 6)

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Then: Cleanup worktree (Step 6)

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then: Cleanup worktree (Step 6)

### Step 6: Cleanup Worktree

**For Options 1, 2, 4:**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge and push (default) | local merge | push | - | delete |
| 2. Create PR | - | push | for review | - |
| 3. Keep as-is | - | - | keep | - |
| 4. Discard | - | - | - | force delete |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" -> ambiguous
- **Fix:** Present exactly 4 structured options

**Automatic worktree cleanup**
- **Problem:** Remove worktree when might need it (Option 2, 3)
- **Fix:** Only cleanup for Options 1 and 4

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only

## Integration

**Called by:**
- **jk-skills:jk-execute** - After all tasks complete
- Any workflow needing branch completion

**Pairs with:**
- **jk-skills:using-git-worktrees** - Cleans up worktree created by that skill
