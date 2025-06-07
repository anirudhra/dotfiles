#!/bin/bash
# creates gtk-4.0 css symlinks
cd ${HOME}/.config
mkdir ./gtk-3.0
mkdir ./gtk-4.0
cd ${HOME}/.config/gtk-3.0
ln -s /usr/share/themes/Orchis-Dark/gtk-3.0/assets ./assets
ln -s /usr/share/themes/Orchis-Dark/gtk-3.0/gtk.css ./gtk.css
ln -s /usr/share/themes/Orchis-Dark/gtk-3.0/gtk-dark.css ./gtk-dark.css

cd ${HOME}/.config/gtk-4.0
ln -s /usr/share/themes/Orchis-Dark/gtk-4.0/assets ./assets
ln -s /usr/share/themes/Orchis-Dark/gtk-4.0/gtk.css ./gtk.css
ln -s /usr/share/themes/Orchis-Dark/gtk-4.0/gtk-dark.css ./gtk-dark.css
