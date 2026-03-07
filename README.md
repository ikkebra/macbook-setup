# MacBook Pro Setup

Automated setup scripts for a fresh macOS installation on MacBook Pro M4 Max.

## What This Does

These scripts configure a complete Laravel development environment from a clean macOS install:

- **System Preferences**: Dark mode, Finder tweaks, Dock hiding, trackpad settings, screenshots, and 100+ macOS defaults
- **Applications**: Browsers (Brave, Firefox, Chromium), dev tools (VS Code, iTerm2, Laravel Herd, DBngin, TablePlus, Transmit, Nova), utilities (Alfred, Raycast, Rectangle, VLC), and more via Homebrew
- **Shell Environment**: Oh My Zsh + Powerlevel10k + curated plugins with a clean .zshrc including Laravel aliases
- **Development Tools**: SSH key generation, git config, VS Code extensions (PHP/Laravel focused), Composer
- **Window Management**: Rectangle with Spectacle-style shortcuts, maximize remapped to Cmd+Option+Up
- **File Associations**: VLC for media, VS Code for code files via duti

## Quick Start

```bash
# Clone this repo to your new Mac
git clone git@github.com:ikkebra/macbook-setup.git ~/setup
cd ~/setup

# Run the bootstrap script (handles everything)
./bootstrap.sh
```

## Script Overview

| Script | Purpose |
|--------|---------|
| `bootstrap.sh` | Entry point — installs Xcode CLI Tools + Homebrew, then runs all other scripts |
| `scripts/install-apps.sh` | Homebrew cask/formula installs (browsers, dev tools, CLI utilities, fonts) |
| `scripts/set-defaults.sh` | macOS system defaults (Finder, Dock, keyboard, screenshots, etc.) |
| `scripts/setup-shell.sh` | Oh My Zsh, Powerlevel10k, zsh plugins, and .zshrc configuration |
| `scripts/setup-dev.sh` | SSH key, git config, VS Code extensions, Composer global setup |
| `scripts/setup-rectangle.sh` | Rectangle window manager with Spectacle shortcuts + custom maximize |
| `scripts/setup-file-defaults.sh` | Default app associations via duti (VLC for media, VS Code for code) |

## Running Individual Scripts

Each script can be run independently:

```bash
./scripts/install-apps.sh    # Just install apps
./scripts/set-defaults.sh    # Just set macOS defaults
./scripts/setup-shell.sh     # Just configure the shell
./scripts/setup-dev.sh       # Just set up dev tools
./scripts/setup-rectangle.sh # Just configure Rectangle
./scripts/setup-file-defaults.sh # Just set file associations
```

## Post-Setup Manual Steps

After running the scripts, a few things need manual attention:

1. **Sign into iCloud** in System Settings
2. **Sign into browsers** — Chromium (work Gmail), Firefox (personal Gmail), Brave (general)
3. **Sign into Alfred** and import license/preferences
4. **Sign into Laravel Herd** and configure sites
5. **Configure DBngin** database servers
6. **Arrange dual monitors** in System Settings > Displays
7. **Run `p10k configure`** in iTerm2 to set up your Powerlevel10k prompt
8. **Add SSH key to GitHub**: `pbcopy < ~/.ssh/id_ed25519.pub` then add at github.com/settings/keys
9. **Sign into VS Code** with GitHub for Settings Sync (optional)
10. **Configure HomePod Minis** as default audio output if desired

## Hardware

- MacBook Pro M4 Max
- Dual Acer ED34OCU monitors
- Stereo-linked HomePod Minis

## Timezone

America/Boise (Mountain Time)
