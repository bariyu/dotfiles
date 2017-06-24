#!/usr/bin/env bash

function copy_system() {
    rsync -r system/ ~/.barandotfiles
}

function copy_vim() {
    cp -R vim/.vimrc ~/
}

function copy_all() {
    copy_system
    copy_vim
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
