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
