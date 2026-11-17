#!/usr/bin/env bash
# Re-vendor the upstream Impeccable skill snapshot.
#
# The official installer is the only thing that knows the skill's current
# layout, so run it into a throwaway project and copy the skill directory it
# produces. Upstream hooks and provider agents are deliberately excluded:
# Agent Hub owns delivery, and the skill works without the hooks.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dest="${root}/adopted-skills/impeccable"
tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT

cd "${tmp}"
npx --yes impeccable install --scope=project --providers=claude --no-hooks -y

src="${tmp}/.claude/skills/impeccable"
test -f "${src}/SKILL.md" || { echo "installer produced no SKILL.md" >&2; exit 1; }

version=$(sed -n 's/^version: *//p' "${src}/SKILL.md" | head -1)
test -n "${version}" || { echo "installed skill has no version" >&2; exit 1; }

rm -rf "${dest}/reference" "${dest}/scripts"
cp "${src}/SKILL.md" "${dest}/SKILL.md"
cp -R "${src}/reference" "${dest}/reference"
cp -R "${src}/scripts" "${dest}/scripts"
if [ -f "${src}/LICENSE" ]; then
    cp "${src}/LICENSE" "${dest}/LICENSE"
else
    curl -fsS https://www.apache.org/licenses/LICENSE-2.0.txt -o "${dest}/LICENSE"
fi

sed -i.bak "/^## Impeccable$/,/^## / s/^Revision: .*/Revision: ${version}/" "${root}/ATTRIBUTION.md"
rm -f "${root}/ATTRIBUTION.md.bak"

echo "vendored impeccable ${version} into ${dest}"
echo "review the diff, then run: just check"
