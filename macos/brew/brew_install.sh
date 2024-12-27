#!/bin/sh

ruby -e "$(curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap homebrew/cask
brew install homebrew/cask/brew-cask

