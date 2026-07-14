#!/usr/bin/env bash
# Runs bootstrap.sh against an isolated HOME and asserts the three symlinks.
set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

# Pre-seed a real file at one target to exercise the backup path.
mkdir -p "$TEST_HOME/.claude"
printf 'old real file\n' > "$TEST_HOME/.claude/CLAUDE.md"

HOME="$TEST_HOME" "$REPO_DIR/bootstrap.sh" --force >/dev/null 2>&1

fail=0
expected="$REPO_DIR/AGENTS.md"
for target in "$TEST_HOME/.claude/CLAUDE.md" "$TEST_HOME/.codex/AGENTS.md" "$TEST_HOME/AGENTS.md"; do
  if [ ! -L "$target" ]; then
    echo "FAIL: $target is not a symlink"; fail=1; continue
  fi
  actual="$(readlink "$target")"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $target -> $actual (expected $expected)"; fail=1
  fi
done

# The pre-existing real file must have been backed up, not destroyed.
if [ ! -f "$TEST_HOME/.claude/CLAUDE.md.backup" ]; then
  echo "FAIL: pre-existing real file was not backed up"; fail=1
fi

if [ "$fail" -eq 0 ]; then echo "PASS"; else exit 1; fi
