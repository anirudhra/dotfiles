#!/usr/bin/env sh
sudo flatpak override --reset --system
sudo flatpak override --system \
  --filesystem="xdg-config/gtkrc-2.0:ro" \
  --filesystem="xdg-config/gtk-3.0:ro" \
  --filesystem="xdg-config/gtk-4.0:ro" \
  --filesystem="xdg-config/gtkrc:ro" \
  --filesystem="xdg-data/icons:ro" \
  --filesystem="xdg-data/themes:ro" \
  --filesystem="/usr/share/themes:ro" \
  --filesystem="/usr/share/icons:ro"
