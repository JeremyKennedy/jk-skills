#!/usr/bin/env bash
set -euo pipefail

errors=0

shopt -s nullglob

# Check all skill directories have SKILL.md
for dir in skills/*/; do
    if [[ ! -f "${dir}SKILL.md" ]]; then
        echo "ERROR: Missing SKILL.md in ${dir}"
        errors=$((errors + 1))
    fi
done

# Check SKILL.md frontmatter has name and description
for skill in skills/*/SKILL.md; do
    if ! head -20 "$skill" | grep -q '^name:'; then
        echo "ERROR: Missing 'name:' in frontmatter of ${skill}"
        errors=$((errors + 1))
    fi
    if ! head -20 "$skill" | grep -q '^description:'; then
        echo "ERROR: Missing 'description:' in frontmatter of ${skill}"
        errors=$((errors + 1))
    fi
done

# Check no superpowers:* references remain
if grep -r 'superpowers:' skills/ agents/ 2>/dev/null; then
    echo "ERROR: Found superpowers:* references (should be jk-skills:*)"
    errors=$((errors + 1))
fi

# Shipped skills must be host/model neutral. Literal Claude model aliases are
# allowed only in warnings that explicitly say not to hardcode them.
model_alias_refs=$(grep -RInwE '(haiku|sonnet|opus|Haiku|Sonnet|Opus)' skills/*/SKILL.md 2>/dev/null | grep -v 'Never hardcode Claude aliases' | grep -v 'skill mentions Claude model aliases' || true)
if [[ -n "$model_alias_refs" ]]; then
    echo "ERROR: Found provider-specific Claude model aliases in shipped skills"
    echo "$model_alias_refs"
    errors=$((errors + 1))
fi

# Shipped skills must not assume CLAUDE.md is the only project instruction file.
claude_md_refs=$(grep -RInE '\bCLAUDE\.md\b' skills/*/SKILL.md 2>/dev/null | grep -vE 'CLAUDE\.md.*AGENTS\.md|AGENTS\.md.*CLAUDE\.md' || true)
if [[ -n "$claude_md_refs" ]]; then
    echo "ERROR: Found bare CLAUDE.md references in shipped skills"
    echo "$claude_md_refs"
    errors=$((errors + 1))
fi

# Shipped skills/references must not contain private personal names.
personal_refs=$(grep -RInE 'Jeremy|jeremy|Kennedy|Jibbs' skills/*/SKILL.md skills/*/references 2>/dev/null || true)
if [[ -n "$personal_refs" ]]; then
    echo "ERROR: Found personal-name references in shipped skills"
    echo "$personal_refs"
    errors=$((errors + 1))
fi

# Pi DeepSeek policy: flash is only for mechanical/no-reasoning tasks; pro is
# only for explicit user requests. Enforce this where model IDs are mentioned in
# shipped skill bodies/references so examples cannot drift into defaults.
deepseek_flash_refs=$(grep -RInE 'deepseek/deepseek-v4-flash|dsv4f' skills/*/SKILL.md skills/*/references 2>/dev/null | grep -viE 'mechanical|no real reasoning|no judgment|purely mechanical' || true)
if [[ -n "$deepseek_flash_refs" ]]; then
    echo "ERROR: Found deepseek-v4-flash references outside mechanical/no-reasoning guidance"
    echo "$deepseek_flash_refs"
    errors=$((errors + 1))
fi

deepseek_pro_refs=$(grep -RInE 'deepseek/deepseek-v4-pro|dsv4p' skills/*/SKILL.md skills/*/references 2>/dev/null | grep -viE 'explicit.*user|user.*explicit' || true)
if [[ -n "$deepseek_pro_refs" ]]; then
    echo "ERROR: Found deepseek-v4-pro references outside explicit-user-request guidance"
    echo "$deepseek_pro_refs"
    errors=$((errors + 1))
fi

# A timeout is a kill/interrupt budget, not a progress signal. Do not bake
# concrete foreground timeout knobs into shipped skill workflows.
timeout_refs=$(grep -RInE 'timeoutMs|maxRuntimeMs' skills/*/SKILL.md 2>/dev/null || true)
if [[ -n "$timeout_refs" ]]; then
    echo "ERROR: Found concrete subagent timeout fields in shipped skills"
    echo "$timeout_refs"
    errors=$((errors + 1))
fi

# Check agent frontmatter has name and description
for agent in agents/*.md; do
    if ! head -10 "$agent" | grep -q '^name:'; then
        echo "ERROR: Missing 'name:' in frontmatter of ${agent}"
        errors=$((errors + 1))
    fi
    if ! head -10 "$agent" | grep -q '^description:'; then
        echo "ERROR: Missing 'description:' in frontmatter of ${agent}"
        errors=$((errors + 1))
    fi
done

# Check shipped Python scripts compile
if command -v python3 >/dev/null 2>&1; then
    while IFS= read -r py; do
        if ! python3 -c 'import ast,sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' "$py" 2>/dev/null; then
            echo "ERROR: Python script does not compile: ${py}"
            errors=$((errors + 1))
        fi
    done < <(find skills -name '*.py' -type f)
fi

# Check sub-skill references point to existing skills
for ref in $(grep -roh 'jk-skills:[a-z-]*' skills/ 2>/dev/null | sort -u); do
    skill_name="${ref#jk-skills:}"
    if [[ ! -d "skills/${skill_name}" ]]; then
        echo "ERROR: Sub-skill reference '${ref}' points to non-existent skill"
        errors=$((errors + 1))
    fi
done

if [[ $errors -gt 0 ]]; then
    echo ""
    echo "FAILED: ${errors} error(s) found"
    exit 1
else
    echo "OK: All checks passed"
fi
