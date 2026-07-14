# Global AGENTS.md with multi-agent symlinks

## Goal

Maintain one canonical global agent-instructions file in the dotfiles repo and
symlink it into the config locations of multiple coding agents, so every agent
reads the same instructions and a single edit updates all of them.

## Decisions

- **Canonical file:** `AGENTS.md` at the dotfiles repo root. This is the single
  real file; everything else is a symlink pointing at it.
- **Targets (3):**
  - `~/.claude/CLAUDE.md`
  - `~/.codex/AGENTS.md`
  - `~/AGENTS.md`
  - Gemini is intentionally excluded.
- **Symlinks point straight into the git repo** (not into `~/.barandotfiles`).
  Editing `AGENTS.md` in the repo updates every agent instantly, no re-run needed.
- **Wiring:** a new `link_agents()` function in the existing `bootstrap.sh`,
  invoked from `copy_all()`. `./bootstrap.sh` remains the one entry point.

## Canonical file content

`AGENTS.md` is the referenced kunchenguid file minus two bullets the user
dropped (auto co-author, CHANGELOG/auto-generated files):

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

## `link_agents()` behavior

Added to `bootstrap.sh` and called from `copy_all()`.

1. Resolve the repo's absolute path so symlink targets are stable regardless of
   the invocation directory.
2. For each target (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/AGENTS.md`):
   - `mkdir -p` the parent directory if it does not exist.
   - If a **real file** (not already a symlink) exists at the target, move it to
     `<target>.backup` before linking, so nothing is silently destroyed.
   - Create/refresh the link: `ln -sfn "$REPO/AGENTS.md" "$target"`.
3. The existing confirmation prompt / `--force` flag continues to gate the whole
   `copy_all` run.

## Result

After `./bootstrap.sh`:

```
~/.claude/CLAUDE.md  -> ~/dev/dotfiles/AGENTS.md
~/.codex/AGENTS.md   -> ~/dev/dotfiles/AGENTS.md
~/AGENTS.md          -> ~/dev/dotfiles/AGENTS.md
```

## Out of scope (YAGNI)

- Gemini target (`~/.gemini/GEMINI.md`).
- Uninstall / unlink command.
- Templating or per-agent variation - one flat file for all.
