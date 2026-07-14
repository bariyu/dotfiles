# Global AGENTS.md with Multi-Agent Symlinks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Maintain one canonical `AGENTS.md` in the dotfiles repo and symlink it into three agent config locations so every agent reads the same instructions.

**Architecture:** A single real file at the repo root is the source of truth. A new `link_agents()` function in the existing `bootstrap.sh` resolves the repo's absolute path and creates idempotent symlinks (`ln -sfn`) at each target, backing up any pre-existing real file. Symlinks point straight into the repo, so editing `AGENTS.md` updates all agents instantly.

**Tech Stack:** Bash, POSIX filesystem symlinks.

## Global Constraints

- Symlink targets (exactly 3): `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/AGENTS.md`.
- Symlinks point to `$REPO/AGENTS.md` (the repo root file), never to `~/.barandotfiles`.
- Gemini (`~/.gemini/GEMINI.md`) is out of scope.
- `link_agents()` must be idempotent and must back up a real (non-symlink) file to `<target>.backup` before overwriting.
- `./bootstrap.sh` stays the single entry point; `link_agents` is called from `copy_all()`.
- The canonical file content is fixed (see Task 1) — the two dropped bullets (co-author, CHANGELOG) must NOT appear.

---

### Task 1: Create the canonical AGENTS.md

**Files:**
- Create: `AGENTS.md` (repo root)

**Interfaces:**
- Consumes: nothing.
- Produces: `AGENTS.md` at repo root — the symlink target that Task 2 points every agent config at.

- [ ] **Step 1: Write the file**

Create `AGENTS.md` at the repo root with exactly this content:

```markdown
# global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed
```

- [ ] **Step 2: Verify content and absence of dropped bullets**

Run:
```bash
grep -c "^- " AGENTS.md && ! grep -qi "co-author\|CHANGELOG" AGENTS.md && echo "OK"
```
Expected: prints `5` then `OK` (5 top-level bullets, neither dropped topic present).

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "feat: add canonical global AGENTS.md"
```

---

### Task 2: Add link_agents() to bootstrap.sh

**Files:**
- Modify: `bootstrap.sh`
- Test: `test/test_link_agents.sh` (create)

**Interfaces:**
- Consumes: `AGENTS.md` from Task 1.
- Produces: `link_agents()` shell function, invoked by `copy_all()`. Creates symlinks `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/AGENTS.md`, each pointing to `$REPO_DIR/AGENTS.md` where `REPO_DIR` is the absolute path of the directory containing `bootstrap.sh`.

- [ ] **Step 1: Write the failing test**

Create `test/test_link_agents.sh`:

```bash
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
```

Make it executable:
```bash
chmod +x test/test_link_agents.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./test/test_link_agents.sh`
Expected: FAIL — targets are not symlinks (function does not exist yet), exit code 1.

- [ ] **Step 3: Add link_agents() and wire it into copy_all()**

Edit `bootstrap.sh`. Add a `REPO_DIR` definition near the top (after the shebang) and a `link_agents()` function, and call it from `copy_all()`. The resulting file:

```bash
#!/usr/bin/env bash

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function copy_system() {
    rsync -r system/ ~/.barandotfiles
}

function copy_vim() {
    cp -R vim/.vimrc ~/
}

function link_agents() {
    local src="$REPO_DIR/AGENTS.md"
    local target
    for target in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md" "$HOME/AGENTS.md"; do
        mkdir -p "$(dirname "$target")"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mv "$target" "$target.backup"
        fi
        ln -sfn "$src" "$target"
    done
}

function copy_all() {
    copy_system
    copy_vim
    link_agents
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	copy_all
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		copy_all
	fi;
fi;
unset copy_all;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./test/test_link_agents.sh`
Expected: `PASS`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add bootstrap.sh test/test_link_agents.sh
git commit -m "feat: symlink global AGENTS.md into agent configs via bootstrap"
```

---

### Task 3: Apply to the live machine and verify

**Files:** none (runtime action).

**Interfaces:**
- Consumes: `link_agents()` from Task 2.
- Produces: live symlinks in the user's real `$HOME`.

- [ ] **Step 1: Run bootstrap for real**

Run: `./bootstrap.sh --force`
Expected: completes without error.

- [ ] **Step 2: Verify the live symlinks**

Run:
```bash
for f in ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/AGENTS.md; do
  printf '%s -> %s\n' "$f" "$(readlink "$f")"
done
```
Expected: each line shows the target pointing to `/Users/baran/dev/dotfiles/AGENTS.md`.

---

## Notes

- The test seeds a real `CLAUDE.md` to exercise the backup branch; on the actual machine all three targets are currently absent (verified during brainstorming), so no `.backup` files are expected in Task 3.
- `ln -sfn` is used (not plain `ln -sf`) so re-running never nests a link inside a previously created symlinked directory.
