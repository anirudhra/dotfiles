# macOS Dotfiles & Workstation Setup

Automated provisioning, package installation, desktop utilities, and configuration profiles for macOS workstations (supporting both Apple Silicon `arm64` and Intel `x86_64`).

---

## Directory Overview

```
macos/
├── macos_install.sh        # Initial installer: Homebrew, CLI tools, GUI casks, fonts, oh-my-zsh
├── macos_post_install.sh   # Post-install: Dotfiles stow, zsh plugins, Karabiner, iTerm2 schemes
├── macos_usb_backup.sh     # External USB backup utility with modern rsync & dry-run support
├── gpu.sh                  # GPU metrics query and live watch monitor
├── gpumon.sh               # Continuous GPU monitor wrapper
├── karabiner/              # Karabiner-Elements complex modifications & keyboard mapping
│   └── karabiner.json
└── iterm2-colors/          # Curated iTerm2 color presets (Catppuccin, Cobalt, Chester, etc.)
    └── *.itermcolors
```

---

## Getting Started

### 1. Run Initial Installation

```bash
cd ~/dotfiles/macos
./macos_install.sh
```

**What it does:**
- Detects CPU architecture (`arm64` vs. `x86_64`).
  - **Apple Silicon (`arm64`)**: Automatically installs Homebrew into `/opt/homebrew` if not present and configures environment paths.
  - **Intel (`x86_64`)**: Uses existing Homebrew if present; skips automated installation if missing.
- Installs essential CLI tools (`fastfetch`, `bat`, `zoxide`, `btop`, `neovim`, `stow`, `gh`, `fzf`, `rsync`, etc.).
- Installs GUI applications via Homebrew Cask (`alfred`, `gimp`, `iterm2`, `vimr`, `xquartz`, `macfuse`).
- Installs Nerd Fonts (`FiraCode`, `Meslo`, `Hack`, `JetBrainsMono`, etc.).
- Installs Oh-My-Zsh non-interactively without hijacking the terminal session.

### 2. Run Post-Installation

```bash
./macos_post_install.sh
```

**What it does:**
- Checks and prompts for GitHub CLI (`gh auth login`) if not authenticated.
- Installs Oh-My-Zsh plugins (`powerlevel10k`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fast-syntax-highlighting`, `zsh-autocomplete`) idempotently using shallow clones.
- Symlinks `macos/karabiner/karabiner.json` into `~/.config/karabiner/karabiner.json`.
- Automatically imports all `.itermcolors` color schemes into iTerm2.
- Backs up conflicting configuration files and deploys dotfiles using GNU Stow.

---

## Included Tools & Utilities

### 1. External USB Backup (`macos_usb_backup.sh`)

Performs an incremental, verified backup of home directories (`Downloads`, `Documents`, `Pictures`) and media (`MusicLibrary`) to an external drive.

```bash
# Preview changes without modifying files (dry-run)
./macos_usb_backup.sh --dry-run

# Run live backup to default volume (/Volumes/BackupPlus)
./macos_usb_backup.sh

# Run backup targeting a custom volume
./macos_usb_backup.sh --volume /Volumes/MyExternalSSD
```

**Features:**
- Automatically detects and utilizes modern Homebrew `rsync` (3.x) over macOS legacy `rsync` 2.6.9.
- Verifies that the destination volume is mounted and writable before executing.
- Preserves exclusions for temporary files (`.DS_Store`, `._*`, `*.tmp`, `.Trash/`, `.Spotlight-V100/`).

### 2. GPU Performance Statistics (`gpu.sh` & `gpumon.sh`)

Queries Apple IORegistry performance statistics (utilization, clock speeds, temperatures, power, and fan RPM).

```bash
# Print current GPU metrics once
./gpu.sh

# Continuous live monitoring (updates immediately, then every 3 seconds)
./gpu.sh --watch

# Custom refresh interval (e.g., 1 second)
./gpu.sh -w 1

# Alias wrapper
./gpumon.sh
```

*(Convenient aliases `gpu` and `gpumon` are pre-configured in `~/.aliases_macos`.)*

### 3. Keyboard Customization (`karabiner/`)

Custom Karabiner-Elements profile providing PC-style navigation (`Home`, `End`), modifier remaps, and application-specific overrides. Symlinked automatically to `~/.config/karabiner/karabiner.json` during post-install.

### 4. Terminal Themes (`iterm2-colors/`)

Includes Catppuccin (Mocha, Macchiato, Frappe, Latte), Cobalt2, Cobalt Neon, and Chester. Automatically imported into iTerm2 during post-install.
