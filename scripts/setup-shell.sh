#!/usr/bin/env bash
#
# setup-shell.sh — Install Oh My Zsh, Powerlevel10k, plugins, and configure .zshrc
#

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step()    { echo ""; echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

###############################################################################
# Oh My Zsh                                                                    #
###############################################################################

step "Installing Oh My Zsh"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    success "Oh My Zsh already installed"
else
    # Install Oh My Zsh (unattended, don't change shell yet)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    success "Oh My Zsh installed"
fi

###############################################################################
# Powerlevel10k                                                                #
###############################################################################

step "Installing Powerlevel10k"

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

if [[ -d "$P10K_DIR" ]]; then
    success "Powerlevel10k already installed"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    success "Powerlevel10k installed"
fi

###############################################################################
# Zsh Plugins                                                                  #
###############################################################################

step "Installing Zsh plugins"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions
if [[ -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
    success "zsh-autosuggestions already installed"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    success "zsh-autosuggestions installed"
fi

# zsh-syntax-highlighting
if [[ -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]]; then
    success "zsh-syntax-highlighting already installed"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting installed"
fi

###############################################################################
# .zshrc                                                                       #
###############################################################################

step "Installing .zshrc"

# Backup existing .zshrc if present
if [[ -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    warn "Existing .zshrc backed up"
fi

# Install new .zshrc
cp "${REPO_DIR}/dotfiles/zshrc" "$HOME/.zshrc"
success ".zshrc installed"

###############################################################################
# iTerm2 — Preferences                                                        #
###############################################################################

step "Configuring iTerm2 preferences"

# Disable "Confirm closing multiple sessions"
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

# Disable "Confirm Quit iTerm2" (Cmd+Q)
defaults write com.googlecode.iterm2 NeverWarnAboutShortLivedSessions_selection -int 0

# Disable all confirmations on system shutdown, restart, and log out
defaults write com.googlecode.iterm2 NeverBlockSystemShutdown -bool true

# Don't display the annoying prompt when quitting iTerm2
defaults write com.googlecode.iterm2 OnlyWhenMoreTabs -bool false

# Set font to MesloLGS NF for Powerlevel10k compatibility
/usr/libexec/PlistBuddy -c "Set ':New Bookmarks:0:Normal Font' MesloLGS-NF-Regular 14" \
    ~/Library/Preferences/com.googlecode.iterm2.plist 2>/dev/null || true

success "iTerm2 closing confirmations disabled"

###############################################################################
# iTerm2 — Catppuccin Mocha Color Scheme                                      #
###############################################################################

step "Installing Catppuccin Mocha color scheme for iTerm2"

ITERM_COLORS_DIR="$HOME/.iterm2"
mkdir -p "$ITERM_COLORS_DIR"

CATPPUCCIN_URL="https://raw.githubusercontent.com/catppuccin/iterm/main/colors/catppuccin-mocha.itermcolors"
CATPPUCCIN_FILE="${ITERM_COLORS_DIR}/catppuccin-mocha.itermcolors"

if [[ -f "$CATPPUCCIN_FILE" ]]; then
    success "Catppuccin Mocha already downloaded"
else
    curl -fsSL "$CATPPUCCIN_URL" -o "$CATPPUCCIN_FILE" 2>/dev/null \
        && success "Catppuccin Mocha downloaded" \
        || warn "Could not download Catppuccin Mocha — install manually from https://github.com/catppuccin/iterm"
fi

# Import the color scheme into iTerm2
# This opens the .itermcolors file which triggers iTerm2's import dialog
if [[ -f "$CATPPUCCIN_FILE" ]]; then
    open "$CATPPUCCIN_FILE" 2>/dev/null || true
    success "Catppuccin Mocha color scheme imported into iTerm2"
    echo "  If iTerm2 is not running, the import will happen on next launch."
    echo "  To activate: iTerm2 > Preferences > Profiles > Colors > Color Presets > Catppuccin Mocha"
fi

###############################################################################
# Set Zsh as default shell                                                     #
###############################################################################

step "Setting Zsh as default shell"

if [[ "$SHELL" == *"zsh"* ]]; then
    success "Zsh is already the default shell"
else
    chsh -s "$(which zsh)"
    success "Default shell changed to Zsh"
fi

echo ""
success "Shell environment configured!"
warn "Open a new terminal or run 'source ~/.zshrc' to apply changes."
warn "Run 'p10k configure' in iTerm2 to set up your Powerlevel10k prompt."
warn "Set Catppuccin Mocha as active: iTerm2 > Preferences > Profiles > Colors > Color Presets"
echo ""
