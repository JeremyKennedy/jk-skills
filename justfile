default:
    @just --list

# Run validation checks
check:
    bash scripts/check.sh

# Build (no-op for content repo, validates structure)
build: check

# Re-vendor the upstream Impeccable skill snapshot
impeccable-update:
    bash scripts/vendor-impeccable.sh

# Development: watch for changes and validate
dev:
    @echo "Skills repo — edit SKILL.md files, run 'just check' to validate."
    @echo "No dev server needed for a content repo."
