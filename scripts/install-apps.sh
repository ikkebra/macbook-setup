#!/usr/bin/env bash
#
# install-apps.sh — Install applications via Homebrew
#

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step()    { echo ""; echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

# Ensure Homebrew is available
if ! command -v brew &>/dev/null; then
    echo "Homebrew is not installed. Run bootstrap.sh first."
    exit 1
fi

###############################################################################
# CLI Tools (Homebrew Formulas)                                                #
###############################################################################

step "Adding Homebrew taps"

brew tap stripe/stripe-cli 2>/dev/null || true
success "Homebrew taps configured"

step "Installing CLI tools via Homebrew"

formulas=(
    # Core utilities
    git
    gh              # GitHub CLI
    wget
    curl
    htop
    jq
    tree
    vim
    coreutils       # GNU core utilities

    # Modern CLI replacements
    ripgrep         # Fast grep alternative (rg)
    bat             # Cat with syntax highlighting
    eza             # Modern ls replacement
    fd              # Fast find alternative
    fzf             # Fuzzy finder
    zoxide          # Smarter cd that learns your habits
    lazygit         # Terminal UI for git
    tldr            # Simplified man pages
    fastfetch       # System info display

    # Development
    composer        # PHP dependency manager
    mailpit         # Local email testing for Laravel
    stripe-cli      # Stripe CLI for payment testing (requires tap below)

    # Claude Code tools
    agent-browser   # Headless browser automation for Claude Code

    # Media
    yt-dlp          # Media downloader
    ffmpeg          # Media processing (needed by yt-dlp)
    imagemagick     # Image manipulation
    exiftool        # Image/file metadata
    tesseract       # OCR engine

    # Networking
    nmap            # Network scanner
    rsync           # Better rsync than macOS built-in

    # Archives
    p7zip           # 7-Zip for .7z files

    # System utilities
    duti            # Set default applications for file types
    mas             # Mac App Store CLI
)

for formula in "${formulas[@]}"; do
    if brew list "$formula" &>/dev/null; then
        success "$formula already installed"
    else
        echo "  Installing $formula..."
        brew install "$formula"
        success "$formula installed"
    fi
done

###############################################################################
# GUI Applications (Homebrew Casks)                                            #
###############################################################################

step "Installing GUI applications via Homebrew Cask"

casks=(
    # Browsers
    brave-browser
    firefox
    chromium
    orion              # Kagi's WebKit browser (used for X/Twitter)
    vivaldi            # Privacy-focused Chromium browser (throwaway logins)

    # Development
    visual-studio-code
    iterm2
    claude-code       # Claude Code CLI
    nova              # Panic's code editor
    sublime-text      # Sublime Text
    tableplus         # Database GUI
    transmit          # File transfer
    meld              # Visual diff tool

    # Laravel ecosystem
    ray               # Spatie Ray — Laravel debugging
    tinkerwell        # Laravel Tinker GUI
    invoker           # Laravel tool

    # Utilities
    alfred
    raycast
    rectangle         # Window management
    vlc               # Media player
    audacity          # Audio editor
    the-unarchiver
    coconutbattery     # Battery health monitoring
    localsend          # Cross-platform file sharing (AirDrop alternative)
    mp3tag             # Audio file tagging
    balenaetcher       # USB image writer
    raspberry-pi-imager

    # Microsoft 365
    microsoft-word
    microsoft-excel
    microsoft-outlook
    microsoft-teams

    # Creative
    inkscape           # Vector graphics editor

    # Communication / Productivity
    claude            # Claude desktop app
    discord
    zoom
    google-chrome     # Needed for some Google Workspace integrations

    # IT / Networking
    vnc-viewer         # Remote desktop
    wireshark          # Network analysis (optional, you had nmap)

    # Remote access
    windows-app        # Microsoft Remote Desktop
)

for cask in "${casks[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        success "$cask already installed"
    else
        echo "  Installing $cask..."
        brew install --cask "$cask"
        success "$cask installed"
    fi
done

###############################################################################
# Apps not in Homebrew (manual install reminders)                              #
###############################################################################

step "Checking for apps that require manual installation"

# Define manual apps: "App Name|URL|check_path"
manual_apps=(
    "Laravel Herd|https://herd.laravel.com|/Applications/Herd.app"
    "DBngin|https://dbngin.com|/Applications/DBngin.app"
    "HELO|https://usehelo.com|/Applications/HELO.app"
    "Adobe Creative Cloud|https://creativecloud.adobe.com|/Applications/Adobe Creative Cloud"
    "UniFi Network|https://ui.com/download/releases/network-server|/Applications/UniFi.app"
    "WiFiman Desktop|https://wifiman.com|/Applications/WiFiman Desktop.app"
    "GoTo|https://www.goto.com/download|/Applications/GoTo.app"
)

missing_apps=()

for entry in "${manual_apps[@]}"; do
    IFS='|' read -r name url path <<< "$entry"
    if [[ -d "$path" ]] || [[ -d "${path}.app" ]]; then
        success "$name already installed"
    else
        missing_apps+=("$name|$url")
    fi
done

if [[ ${#missing_apps[@]} -gt 0 ]]; then
    echo ""
    warn "The following apps need to be downloaded manually:"
    echo ""
    for entry in "${missing_apps[@]}"; do
        IFS='|' read -r name url <<< "$entry"
        echo -e "  ${YELLOW}${name}${NC}"
        echo -e "  ${BLUE}${url}${NC}"
        echo ""
    done

    # Offer to open all download links in browser
    read -p "Open all download links in your browser? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for entry in "${missing_apps[@]}"; do
            IFS='|' read -r name url <<< "$entry"
            open "$url"
            sleep 0.5
        done
        success "Opened download pages in your default browser"
    fi
else
    success "All manual apps already installed!"
fi

###############################################################################
# Fonts                                                                        #
###############################################################################

step "Installing fonts"

# Tap the fonts cask
brew tap homebrew/cask-fonts 2>/dev/null || true

fonts=(
    font-meslo-lg-nerd-font    # Required for Powerlevel10k
    font-jetbrains-mono        # Great coding font (backup)
)

for font in "${fonts[@]}"; do
    if brew list --cask "$font" &>/dev/null; then
        success "$font already installed"
    else
        echo "  Installing $font..."
        brew install --cask "$font"
        success "$font installed"
    fi
done

###############################################################################
# Laravel Installer via Composer                                               #
###############################################################################

step "Installing Laravel Installer via Composer"

if command -v composer &>/dev/null; then
    composer global require laravel/installer 2>/dev/null || warn "Composer global install skipped (may need Herd PHP first)"
    success "Laravel Installer configured"
else
    warn "Composer not yet available — install Laravel Installer after Herd is set up"
fi

###############################################################################
# fzf key bindings                                                             #
###############################################################################

step "Setting up fzf key bindings"

if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    success "fzf key bindings configured"
fi

echo ""
success "All applications installed!"
echo ""
