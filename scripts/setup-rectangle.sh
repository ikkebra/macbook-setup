#!/usr/bin/env bash
#
# setup-rectangle.sh — Configure Rectangle with Spectacle-style shortcuts
# Plus custom remap: Cmd+Option+Up = Maximize (Top Half disabled)
#

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step()    { echo ""; echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

###############################################################################
# Rectangle Configuration                                                     #
###############################################################################

step "Configuring Rectangle"

# Check if Rectangle is installed
if [[ ! -d "/Applications/Rectangle.app" ]]; then
    warn "Rectangle is not installed yet — skipping configuration"
    warn "Run install-apps.sh first, then re-run this script"
    exit 0
fi

# Kill Rectangle if running so we can write its defaults
killall Rectangle 2>/dev/null || true
sleep 1

# Rectangle stores its config in com.knollsoft.Rectangle
# First, set it to use Spectacle-style shortcuts as the base
defaults write com.knollsoft.Rectangle alternateDefaultShortcuts -bool true

# Launch on login
defaults write com.knollsoft.Rectangle launchOnLogin -bool true

# Hide menu bar icon (optional — set to false if you want to see it)
defaults write com.knollsoft.Rectangle hideMenubarIcon -bool false

# Cycle through sizes on repeated execution (half → two-thirds → one-third)
# 0 = cycle half/two-thirds/one-third, 1 = move to next display, 2 = disabled
defaults write com.knollsoft.Rectangle subsequentExecutionMode -int 0

# Now override specific shortcuts using Rectangle's keycode format
# Rectangle uses a JSON-like format for shortcut overrides:
#   keyCode: macOS virtual keycode
#   modifierFlags: bitmask (Cmd=1048576, Option=524288, Ctrl=262144, Shift=131072)
#
# Cmd+Option = 1048576 + 524288 = 1572864
#
# Key codes:
#   Up Arrow = 126
#   Down Arrow = 125
#   Left Arrow = 123
#   Right Arrow = 124
#   F = 3

# Spectacle defaults that Rectangle's alternateDefaultShortcuts gives us:
#   Left Half:    Cmd+Option+Left  (keyCode 123, modifiers 1572864)
#   Right Half:   Cmd+Option+Right (keyCode 124, modifiers 1572864)
#   Top Half:     Cmd+Option+Up    (keyCode 126, modifiers 1572864)
#   Bottom Half:  Cmd+Option+Down  (keyCode 125, modifiers 1572864)
#   Maximize:     Cmd+Option+F     (keyCode 3, modifiers 1572864)
#
# We want to change:
#   Maximize:  Cmd+Option+Up (keyCode 126, modifiers 1572864)
#   Top Half:  DISABLED

# Set Maximize to Cmd+Option+Up
defaults write com.knollsoft.Rectangle maximize -dict-add keyCode -float 126
defaults write com.knollsoft.Rectangle maximize -dict-add modifierFlags -float 1572864

# Disable Top Half by setting an empty/impossible shortcut
# Setting keyCode to 999 effectively disables it
defaults write com.knollsoft.Rectangle topHalf -dict-add keyCode -float 999
defaults write com.knollsoft.Rectangle topHalf -dict-add modifierFlags -float 0

# Also disable the old maximize shortcut (Cmd+Option+F) since we moved it
# This prevents confusion — Cmd+Option+F now does nothing
defaults write com.knollsoft.Rectangle maximize -dict-add keyCode -float 126
defaults write com.knollsoft.Rectangle maximize -dict-add modifierFlags -float 1572864

success "Rectangle configured with Spectacle defaults"
success "Maximize remapped to Cmd+Option+Up"
success "Top Half shortcut disabled"

# Relaunch Rectangle
step "Relaunching Rectangle"
open -a Rectangle
sleep 2
success "Rectangle relaunched"

echo ""
success "Rectangle setup complete!"
echo ""
echo "  Shortcuts:"
echo "    Left Half:    Cmd+Option+Left"
echo "    Right Half:   Cmd+Option+Right"
echo "    Maximize:     Cmd+Option+Up"
echo "    Bottom Half:  Cmd+Option+Down"
echo "    Top Half:     DISABLED"
echo ""
