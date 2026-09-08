#!/usr/bin/env bash
set -euo pipefail

errors=0

shopt -s nullglob

# ── Inventory: exactly five skills ────────────────────────────────────────

actual_skills=($(ls -d skills/*/ 2>/dev/null | xargs -n1 basename | sort))
expected_skills=("jk-converse" "jk-interview" "jk-philosophy" "jk-reflect" "jk-remember")

if [[ "${#actual_skills[@]}" -ne 5 ]]; then
    echo "ERROR: Expected 5 skill directories, found ${#actual_skills[@]}: ${actual_skills[*]}"
    errors=$((errors + 1))
else
    for i in "${!expected_skills[@]}"; do
        if [[ "${actual_skills[$i]}" != "${expected_skills[$i]}" ]]; then
            echo "ERROR: Skill mismatch at index $i: expected ${expected_skills[$i]}, got ${actual_skills[$i]}"
            errors=$((errors + 1))
        fi
    done
fi

# ── Adopted skill inventory and policy ─────────────────────────────────────

adopted_skills=("i-have-adhd" "ponytail" "ponytail-audit" "ponytail-review")
for skill in "${adopted_skills[@]}"; do
    skill_dir="adopted-skills/${skill}"
    test -f "${skill_dir}/SKILL.md" || { echo "ERROR: Missing ${skill_dir}/SKILL.md"; errors=$((errors + 1)); }
    test -f "${skill_dir}/agents/openai.yaml" || { echo "ERROR: Missing ${skill_dir}/agents/openai.yaml"; errors=$((errors + 1)); }
    head -20 "${skill_dir}/SKILL.md" | grep -q '^disable-model-invocation: true$' || {
        echo "ERROR: ${skill} is not manual-only"
        errors=$((errors + 1))
    }
    grep -q '^  allow_implicit_invocation: false$' "${skill_dir}/agents/openai.yaml" || {
        echo "ERROR: ${skill} Codex policy allows implicit invocation"
        errors=$((errors + 1))
    }
done

if find adopted-skills -type d \( -name hooks -o -name extensions -o -name plugins \) -print -quit | grep -q .; then
    echo "ERROR: adopted-skills contains runtime extension directories"
    errors=$((errors + 1))
fi

# ── SKILL.md frontmatter ───────────────────────────────────────────────────

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

# ── Instruction budgets ────────────────────────────────────────────────────

phil_words=$(sed -n '/^# Development Philosophy/,$p' skills/jk-philosophy/SKILL.md | wc -w)
if [[ "$phil_words" -gt 250 ]]; then
    echo "ERROR: jk-philosophy body is $phil_words words (max 250)"
    errors=$((errors + 1))
fi

total_words=0
for skill in skills/jk-philosophy/SKILL.md skills/jk-reflect/SKILL.md skills/jk-remember/SKILL.md skills/jk-converse/SKILL.md skills/jk-interview/SKILL.md; do
    body_start=$(grep -n '^# ' "$skill" | head -1 | cut -d: -f1)
    if [[ -n "$body_start" ]]; then
        words=$(sed -n "${body_start},\$p" "$skill" | wc -w)
        total_words=$((total_words + words))
    fi
done
if [[ "$total_words" -gt 2500 ]]; then
    echo "ERROR: Combined five SKILL.md bodies are $total_words words (max 2500)"
    errors=$((errors + 1))
fi

# ── Host/model neutrality ─────────────────────────────────────────────────

model_alias_refs=$(grep -RInwE '(haiku|sonnet|opus|Haiku|Sonnet|Opus)' skills/*/SKILL.md 2>/dev/null | grep -v 'Never hardcode Claude aliases' | grep -v 'skill mentions Claude model aliases' || true)
if [[ -n "$model_alias_refs" ]]; then
    echo "ERROR: Found provider-specific Claude model aliases in shipped skills"
    echo "$model_alias_refs"
    errors=$((errors + 1))
fi

claude_md_refs=$(grep -RInE '\bCLAUDE\.md\b' skills/*/SKILL.md 2>/dev/null | grep -vE 'CLAUDE\.md.*AGENTS\.md|AGENTS\.md.*CLAUDE\.md' || true)
if [[ -n "$claude_md_refs" ]]; then
    echo "ERROR: Found bare CLAUDE.md references in shipped skills"
    echo "$claude_md_refs"
    errors=$((errors + 1))
fi

personal_refs=$(grep -RInE 'Jeremy|jeremy|Kennedy|Jibbs' skills/*/SKILL.md skills/*/references 2>/dev/null || true)
if [[ -n "$personal_refs" ]]; then
    echo "ERROR: Found personal-name references in shipped skills"
    echo "$personal_refs"
    errors=$((errors + 1))
fi

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

timeout_refs=$(grep -RInE 'timeoutMs|maxRuntimeMs' skills/*/SKILL.md 2>/dev/null || true)
if [[ -n "$timeout_refs" ]]; then
    echo "ERROR: Found concrete subagent timeout fields in shipped skills"
    echo "$timeout_refs"
    errors=$((errors + 1))
fi

# ── No retired infrastructure ──────────────────────────────────────────────

for dir in agents hooks upstream .claude; do
    if [[ -d "$dir" ]]; then
        echo "ERROR: Retired directory still exists: ${dir}/"
        errors=$((errors + 1))
    fi
done

# ── Shipped Python scripts compile ─────────────────────────────────────────

if command -v python3 >/dev/null 2>&1; then
    while IFS= read -r py; do
        if ! python3 -c 'import ast,sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' "$py" 2>/dev/null; then
            echo "ERROR: Python script does not compile: ${py}"
            errors=$((errors + 1))
        fi
    done < <(find skills -name '*.py' -type f)
fi

# ── No sub-skill references ────────────────────────────────────────────────

sub_refs=$(grep -roh 'jk-skills:[a-z-]*' skills/ 2>/dev/null || true)
if [[ -n "$sub_refs" ]]; then
    echo "ERROR: Found jk-skills: sub-skill references — companions don't cross-reference"
    echo "$sub_refs"
    errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
    echo ""
    echo "FAILED: ${errors} error(s) found"
    exit 1
else
    echo "OK: All checks passed"
fi
