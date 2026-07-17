#!/usr/bin/env bash
# Runs bootstrap.sh against an isolated HOME and asserts:
#   - the three AGENTS.md symlinks resolve to the repo file
#   - a pre-existing real file is backed up with its content preserved
#   - a stale <target>.backup is never clobbered (displaced file gets .backup.N)
#   - re-running is idempotent and creates no new backups
set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

fail=0
check_link() { # target
  local target="$1" expected="$REPO_DIR/AGENTS.md" actual
  if [ ! -L "$target" ]; then echo "FAIL: $target is not a symlink"; fail=1; return; fi
  actual="$(readlink "$target")"
  [ "$actual" = "$expected" ] || { echo "FAIL: $target -> $actual (expected $expected)"; fail=1; }
}
check_content() { # file expected-content
  local file="$1" want="$2" got
  if [ ! -f "$file" ]; then echo "FAIL: expected file missing: $file"; fail=1; return; fi
  got="$(cat "$file")"
  [ "$got" = "$want" ] || { echo "FAIL: $file content '$got' (expected '$want')"; fail=1; }
}
check_absent() { # path
  [ ! -e "$1" ] || { echo "FAIL: expected absent but present: $1"; fail=1; }
}

# Seed: a real file at one target (exercises backup + content preservation).
mkdir -p "$TEST_HOME/.claude"
printf 'old real file\n' > "$TEST_HOME/.claude/CLAUDE.md"

# Seed: a real file AND a stale .backup at another target (exercises non-clobber).
printf 'home real\n'    > "$TEST_HOME/AGENTS.md"
printf 'stale backup\n' > "$TEST_HOME/AGENTS.md.backup"

# --- First run ---
HOME="$TEST_HOME" "$REPO_DIR/bootstrap.sh" --force >/dev/null 2>&1

check_link "$TEST_HOME/.claude/CLAUDE.md"
check_link "$TEST_HOME/.codex/AGENTS.md"
check_link "$TEST_HOME/AGENTS.md"

# Backup preserves the original file's content.
check_content "$TEST_HOME/.claude/CLAUDE.md.backup" "old real file"

# Stale .backup is not clobbered; the displaced real file lands in .backup.1.
check_content "$TEST_HOME/AGENTS.md.backup"   "stale backup"
check_content "$TEST_HOME/AGENTS.md.backup.1" "home real"

# --- Second run (idempotency) ---
HOME="$TEST_HOME" "$REPO_DIR/bootstrap.sh" --force >/dev/null 2>&1

check_link "$TEST_HOME/.claude/CLAUDE.md"
check_link "$TEST_HOME/.codex/AGENTS.md"
check_link "$TEST_HOME/AGENTS.md"

# Targets are already symlinks now, so no new backups are created.
check_absent "$TEST_HOME/.claude/CLAUDE.md.backup.1"
check_absent "$TEST_HOME/AGENTS.md.backup.2"

if [ "$fail" -eq 0 ]; then echo "PASS"; else exit 1; fi
