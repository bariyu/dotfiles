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
