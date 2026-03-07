#!/usr/bin/env bash
#
# bootstrap.sh — Entry point for MacBook Pro setup
# Installs prerequisites then orchestrates all setup scripts.
#

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step()    { echo ""; echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
fail()    { echo -e "${RED}✗${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║     MacBook Pro M4 Max — Fresh Setup         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

###############################################################################
# Xcode Command Line Tools                                                    #
###############################################################################

step "Checking for Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
    success "Xcode CLT already installed"
else
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install

    # Wait for installation to complete
    echo "Waiting for Xcode CLT installation to complete..."
    echo "A dialog box should have appeared — click 'Install' and wait."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    success "Xcode CLT installed"
fi

###############################################################################
# Homebrew                                                                     #
###############################################################################

step "Checking for Homebrew"

if command -v brew &>/dev/null; then
    success "Homebrew already installed"
else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"

    success "Homebrew installed"
fi

step "Updating Homebrew"
brew update
success "Homebrew updated"

step "Disabling Homebrew analytics"
brew analytics off
success "Homebrew analytics disabled"

step "Setting up Homebrew auto-update"
brew tap homebrew/autoupdate 2>/dev/null || true
# Run brew update + upgrade every 24 hours (86400 seconds) in the background
brew autoupdate start 86400 --upgrade --cleanup 2>/dev/null \
    && success "Homebrew auto-update enabled (every 24 hours)" \
    || warn "Homebrew auto-update setup skipped — set up manually with: brew autoupdate start"

###############################################################################
# Run setup scripts                                                            #
###############################################################################

scripts=(
    "scripts/install-apps.sh"
    "scripts/set-defaults.sh"
    "scripts/setup-shell.sh"
    "scripts/setup-dev.sh"
    "scripts/setup-rectangle.sh"
    "scripts/setup-file-defaults.sh"
)

for script in "${scripts[@]}"; do
    script_path="${SCRIPT_DIR}/${script}"
    if [[ -f "$script_path" ]]; then
        step "Running ${script}..."
        chmod +x "$script_path"
        bash "$script_path"
        success "Completed ${script}"
    else
        warn "Script not found: ${script} — skipping"
    fi
done

###############################################################################
# Done                                                                         #
###############################################################################

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║          Setup Complete!                      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
success "All scripts have been executed."
echo ""
warn "Manual steps remaining:"
echo "  1. Sign into iCloud"
echo "  2. Sign into browsers (Chromium=work, Firefox=personal, Brave=general)"
echo "  3. Import Alfred license/preferences"
echo "  4. Sign into Laravel Herd and configure sites"
echo "  5. Configure DBngin database servers"
echo "  6. Arrange dual Acer monitors in System Settings > Displays"
echo "  7. Run 'p10k configure' in iTerm2"
echo "  8. Add SSH key to GitHub: pbcopy < ~/.ssh/id_ed25519.pub"
echo "  9. Log out and back in for all defaults to take effect"
echo ""
