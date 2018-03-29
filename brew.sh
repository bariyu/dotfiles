#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

brew install bash
brew install wget --with-iri
brew install git
brew install python
brew install sqlite
brew install tig
brew install tree
brew install tmux
brew install htop-osx
brew install openssl
brew install jq
brew install rsync
brew install bash-completion2
brew install cowsay
brew install httpie

brew cleanup
