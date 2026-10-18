#!/bin/bash
# (c) Anirudh Acharya 2024, 2025, 2026
# Download and install Nerd Fonts cleanly with automatic cleanup and modern XDG font path support
# Originally inspired by: https://github.com/officialrajdeepsingh/nerd-fonts-installer
set -euo pipefail

echo
echo "############################"
echo "[-] Download Nerd Fonts [-]"
echo "############################"
echo
echo "Select Nerd Font to install:"

NERDFONTS_LIST=(
  "Agave" "AnonymousPro" "Arimo" "AurulentSansMono" "BigBlueTerminal"
  "BitstreamVeraSansMono" "CascadiaCode" "CodeNewRoman" "ComicShannsMono"
  "Cousine" "DaddyTimeMono" "DejaVuSansMono" "FantasqueSansMono" "FiraCode"
  "FiraMono" "Gohu" "Go-Mono" "Hack" "Hasklig" "HeavyData" "Hermit"
  "iA-Writer" "IBMPlexMono" "InconsolataGo" "InconsolataLGC" "Inconsolata"
  "IosevkaTerm" "JetBrainsMono" "Lekton" "LiberationMono" "Lilex" "Meslo"
  "Monofur" "Monoid" "Mononoki" "MPlus" "NerdFontsSymbolsOnly" "Noto"
  "OpenDyslexic" "Overpass" "ProFont" "ProggyClean" "RobotoMono"
  "ShareTechMono" "SourceCodePro" "SpaceMono" "Terminus" "Tinos"
  "UbuntuMono" "Ubuntu" "VictorMono"
)

echo
PS3="Enter a number: "

select FONT_NAME in "${NERDFONTS_LIST[@]}" "Quit"; do
  if [ -z "${FONT_NAME:-}" ]; then
    echo "Invalid selection. Please choose a number from the list above."
    continue
  fi

  if [ "$FONT_NAME" = "Quit" ]; then
    echo "Exiting font installer."
    exit 0
  fi

  # Determine target font directory (modern XDG specification or macOS library)
  if [ "$(uname)" = "Darwin" ]; then
    FONT_DIR="${HOME}/Library/Fonts/${FONT_NAME}"
  else
    FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/${FONT_NAME}"
  fi

  DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"

  # Create a clean temporary directory with guaranteed cleanup on exit or interrupt
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT INT TERM
  TMP_ZIP="$TMP_DIR/${FONT_NAME}.zip"

  echo "==> Downloading ${FONT_NAME} Nerd Font from GitHub..."
  echo "    $DOWNLOAD_URL"

  if command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar -o "$TMP_ZIP" "$DOWNLOAD_URL"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$TMP_ZIP" "$DOWNLOAD_URL"
  else
    echo "Error: Neither curl nor wget was found. Please install one first." >&2
    exit 1
  fi

  echo "==> Installing font files into: $FONT_DIR"
  mkdir -p "$FONT_DIR"
  unzip -q -o "$TMP_ZIP" -d "$FONT_DIR"

  # Refresh font cache targeted directly to user fonts (much faster than full system cache rebuild)
  if command -v fc-cache >/dev/null 2>&1; then
    echo "==> Updating font cache..."
    fc-cache -f "$FONT_DIR"
  fi

  echo "==> Successfully installed ${FONT_NAME} Nerd Font!"
  break
done
