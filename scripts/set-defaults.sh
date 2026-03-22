#!/usr/bin/env bash
#
# set-defaults.sh — Configure macOS defaults for development
# Supports two modes:
#   1) Express — Apply Ryan's opinionated defaults automatically
#   2) Interactive — Walk through each setting and choose
#

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step()    { echo ""; echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}  ✓${NC} $1"; }
skip()    { echo -e "${YELLOW}  ⏭${NC} $1"; }
info()    { echo -e "${CYAN}  ℹ${NC} $1"; }

# Track what needs restarting
RESTART_DOCK=false
RESTART_FINDER=false
RESTART_SYSUI=false
CHANGES_MADE=0

###############################################################################
# Helper functions for interactive mode                                        #
###############################################################################

# Yes/no question with default
# Usage: ask "Question" "y" → returns 0 (true) if yes, 1 if no
ask() {
    local prompt="$1"
    local default="${2:-y}"
    local hint

    if [[ "$default" == "y" ]]; then hint="Y/n"; else hint="y/N"; fi

    echo ""
    read -p "$(echo -e "  ${BOLD}${prompt}${NC} [${hint}] ")" -n 1 -r
    echo ""

    if [[ -z "$REPLY" ]]; then
        [[ "$default" == "y" ]] && return 0 || return 1
    fi
    [[ "$REPLY" =~ ^[Yy]$ ]] && return 0 || return 1
}

# Pick from numbered options
# Usage: pick "Question" "Option A" "Option B" ...
# Returns the 1-based index in $PICK_RESULT
pick() {
    local question="$1"
    shift
    local options=("$@")

    echo ""
    echo -e "  ${BOLD}${question}${NC}"
    for i in "${!options[@]}"; do
        echo -e "    ${CYAN}$((i+1))${NC}) ${options[$i]}"
    done

    while true; do
        read -p "$(echo -e "    Choice [1-${#options[@]}]: ")" -r
        if [[ "$REPLY" =~ ^[0-9]+$ ]] && (( REPLY >= 1 && REPLY <= ${#options[@]} )); then
            PICK_RESULT=$REPLY
            return 0
        fi
        echo "    Please enter a number between 1 and ${#options[@]}"
    done
}

###############################################################################
# Mode selection                                                               #
###############################################################################

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║               macOS Defaults Configuration                  ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Close System Settings before continuing."
echo ""
echo -e "  ${CYAN}1${NC}) ${BOLD}Express${NC} — Apply all defaults automatically (opinionated)"
echo -e "  ${CYAN}2${NC}) ${BOLD}Interactive${NC} — Walk through each setting and choose"
echo ""

while true; do
    read -p "  Choose mode [1/2]: " -n 1 -r
    echo ""
    if [[ "$REPLY" =~ ^[12]$ ]]; then
        break
    fi
    echo "  Please enter 1 or 2"
done

if [[ "$REPLY" == "1" ]]; then
    MODE="express"
    echo ""
    echo -e "  ${GREEN}Express mode${NC} — applying all defaults..."
else
    MODE="interactive"
    echo ""
    echo -e "  ${GREEN}Interactive mode${NC} — you'll be asked about each setting."
fi

# Ask for administrator password upfront
sudo -v

# Keep sudo alive until script completes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# Appearance                                                                   #
###############################################################################

step "APPEARANCE"

if [[ "$MODE" == "express" ]]; then
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
    defaults write NSGlobalDomain AppleAccentColor -int 4
    defaults write NSGlobalDomain AppleHighlightColor -string "0.698039 0.843137 1.000000 Blue"
    # Disable icons in menus (macOS Tahoe+)
    defaults write -g NSMenuEnableActionImages -bool NO
    success "Dark Mode, blue accent, no menu icons"
    ((CHANGES_MADE++))
else
    if ask "Enable Dark Mode?"; then
        defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
        success "Dark Mode enabled"
    else
        defaults delete NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true
        success "Light Mode set"
    fi
    ((CHANGES_MADE++))

    pick "Accent color?" "Blue (default)" "Purple" "Pink" "Red" "Orange" "Yellow" "Green" "Graphite"
    accent_ids=(4 5 6 0 1 2 3 -1)
    accent_colors=(
        "0.698039 0.843137 1.000000 Blue"
        "0.968627 0.831373 1.000000 Purple"
        "1.000000 0.749020 0.823529 Pink"
        "1.000000 0.733333 0.721569 Red"
        "1.000000 0.874510 0.701961 Orange"
        "1.000000 0.937255 0.690196 Yellow"
        "0.752941 0.964706 0.678431 Green"
        "0.847059 0.847059 0.862745 Graphite"
    )
    defaults write NSGlobalDomain AppleAccentColor -int "${accent_ids[$((PICK_RESULT-1))]}"
    defaults write NSGlobalDomain AppleHighlightColor -string "${accent_colors[$((PICK_RESULT-1))]}"
    success "Accent color set"
    ((CHANGES_MADE++))

    if ask "Disable icons in menus (macOS Tahoe+)?"; then
        defaults write -g NSMenuEnableActionImages -bool NO
        success "Menu icons disabled"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Menu Bar                                                                     #
###############################################################################

step "MENU BAR"

if [[ "$MODE" == "express" ]]; then
    defaults write com.apple.menuextra.battery ShowPercent -string "YES"
    defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
    defaults -currentHost write com.apple.controlcenter.plist BatteryShowPercentage -bool true
    defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true
    defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true
    defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
    defaults write com.apple.menuextra.clock DateFormat -string "HH:mm"
    success "24h clock, battery %, Bluetooth, volume icons"
    ((CHANGES_MADE++))
    RESTART_SYSUI=true
else
    if ask "Show battery percentage in menu bar?"; then
        defaults write com.apple.menuextra.battery ShowPercent -string "YES"
        defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
        defaults -currentHost write com.apple.controlcenter.plist BatteryShowPercentage -bool true
        success "Battery percentage enabled"
        ((CHANGES_MADE++))
        RESTART_SYSUI=true
    fi

    if ask "Always show Bluetooth icon in menu bar?"; then
        defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true
        success "Bluetooth icon enabled"
        ((CHANGES_MADE++))
        RESTART_SYSUI=true
    fi

    if ask "Always show volume/sound icon in menu bar?"; then
        defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true
        success "Volume icon enabled"
        ((CHANGES_MADE++))
        RESTART_SYSUI=true
    fi

    pick "Clock format?" "24-hour (e.g. 14:30)" "12-hour (e.g. 2:30 PM)"
    if [[ $PICK_RESULT -eq 1 ]]; then
        defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
        defaults write com.apple.menuextra.clock DateFormat -string "HH:mm"
        success "24-hour clock set"
    else
        defaults write NSGlobalDomain AppleICUForce24HourTime -bool false
        defaults write com.apple.menuextra.clock DateFormat -string "h:mm a"
        success "12-hour clock set"
    fi
    ((CHANGES_MADE++))
    RESTART_SYSUI=true
fi

###############################################################################
# General UI/UX                                                                #
###############################################################################

step "GENERAL UI/UX"

if [[ "$MODE" == "express" ]]; then
    sudo nvram SystemAudioVolume=" "
    defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
    defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
    defaults write com.apple.LaunchServices LSQuarantine -bool false
    defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
    defaults write com.apple.loginwindow TALLogoutSavesState -bool false
    defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
    defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
    sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    success "General UI/UX configured"
    ((CHANGES_MADE++))
else
    if ask "Disable the startup boot sound?"; then
        sudo nvram SystemAudioVolume=" "
        success "Boot sound disabled"
        ((CHANGES_MADE++))
    fi

    if ask "Expand save and print panels by default?"; then
        defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
        defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
        defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
        defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
        success "Save/print panels expanded by default"
        ((CHANGES_MADE++))
    fi

    if ask "Save to disk (not iCloud) by default?"; then
        defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
        success "Default save location: disk"
        ((CHANGES_MADE++))
    fi

    if ask "Disable the 'Are you sure you want to open this application?' dialog?"; then
        defaults write com.apple.LaunchServices LSQuarantine -bool false
        success "Gatekeeper dialog disabled"
        ((CHANGES_MADE++))
    fi

    if ask "Disable 'Reopen windows when logging back in' on shutdown?"; then
        defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
        defaults write com.apple.loginwindow TALLogoutSavesState -bool false
        defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
        success "Window restore on logout disabled"
        ((CHANGES_MADE++))
    fi

    if ask "Disable smart quotes, smart dashes, auto-correct, and auto-capitalization?"; then
        defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
        defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
        defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
        defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
        defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
        success "Smart text features disabled"
        ((CHANGES_MADE++))
    fi

    if ask "Show IP/hostname info when clicking login window clock?"; then
        sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
        success "Login window info enabled"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Trackpad                                                                     #
###############################################################################

step "TRACKPAD"

if [[ "$MODE" == "express" ]]; then
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false
    defaults write com.apple.accessibility com.apple.Accessibility.DragLock.FeatureEnabled -bool true 2>/dev/null || true
    success "Traditional scrolling, three-finger drag"
    ((CHANGES_MADE++))
else
    pick "Scroll direction?" "Traditional (down is down)" "Natural (Apple default — content follows finger)"
    if [[ $PICK_RESULT -eq 1 ]]; then
        defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
        success "Traditional scrolling set"
    else
        defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
        success "Natural scrolling set"
    fi
    ((CHANGES_MADE++))

    if ask "Enable three-finger drag?"; then
        defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
        defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false
        defaults write com.apple.accessibility com.apple.Accessibility.DragLock.FeatureEnabled -bool true 2>/dev/null || true
        success "Three-finger drag enabled"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# SSD-specific tweaks                                                          #
###############################################################################

step "SSD OPTIMIZATIONS"

if [[ "$MODE" == "express" ]]; then
    sudo pmset -a hibernatemode 0
    sudo pmset -a sms 0
    success "SSD optimizations applied"
    ((CHANGES_MADE++))
else
    if ask "Disable hibernation and sudden motion sensor (recommended for SSDs)?"; then
        sudo pmset -a hibernatemode 0
        sudo pmset -a sms 0
        success "SSD optimizations applied"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Keyboard and input                                                           #
###############################################################################

step "KEYBOARD & INPUT"

if [[ "$MODE" == "express" ]]; then
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
    defaults write NSGlobalDomain AppleLanguages -array "en"
    defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
    defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"
    defaults write NSGlobalDomain AppleMetricUnits -bool false
    systemsetup -settimezone "America/Boise" > /dev/null
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    success "Keyboard configured (fast repeat, Mountain time)"
    ((CHANGES_MADE++))
else
    if ask "Enable full keyboard access (Tab through all UI controls)?"; then
        defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
        success "Full keyboard access enabled"
        ((CHANGES_MADE++))
    fi

    pick "Timezone?" "America/Boise (Mountain)" "America/New_York (Eastern)" "America/Chicago (Central)" "America/Los_Angeles (Pacific)" "America/Denver (Mountain)" "America/Anchorage (Alaska)" "Pacific/Honolulu (Hawaii)" "UTC"
    timezones=("America/Boise" "America/New_York" "America/Chicago" "America/Los_Angeles" "America/Denver" "America/Anchorage" "Pacific/Honolulu" "UTC")
    systemsetup -settimezone "${timezones[$((PICK_RESULT-1))]}" > /dev/null
    success "Timezone set to ${timezones[$((PICK_RESULT-1))]}"
    ((CHANGES_MADE++))

    pick "Key repeat speed?" "Fast (developer-friendly)" "Medium" "Slow (macOS default)"
    case $PICK_RESULT in
        1) defaults write NSGlobalDomain KeyRepeat -int 2
           defaults write NSGlobalDomain InitialKeyRepeat -int 15
           success "Fast key repeat set" ;;
        2) defaults write NSGlobalDomain KeyRepeat -int 3
           defaults write NSGlobalDomain InitialKeyRepeat -int 25
           success "Medium key repeat set" ;;
        3) defaults write NSGlobalDomain KeyRepeat -int 6
           defaults write NSGlobalDomain InitialKeyRepeat -int 68
           success "Default key repeat set" ;;
    esac
    ((CHANGES_MADE++))
fi

###############################################################################
# Screen                                                                       #
###############################################################################

step "SCREEN & SECURITY"

if [[ "$MODE" == "express" ]]; then
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    success "Password required immediately after sleep"
    ((CHANGES_MADE++))
else
    if ask "Require password immediately after sleep or screen saver?"; then
        defaults write com.apple.screensaver askForPassword -int 1
        defaults write com.apple.screensaver askForPasswordDelay -int 0
        success "Immediate password requirement set"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Finder                                                                       #
###############################################################################

step "FINDER"

if [[ "$MODE" == "express" ]]; then
    defaults write com.apple.finder NewWindowTarget -string "PfDe"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowToolbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
    defaults write com.apple.finder QLEnableTextSelection -bool true
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    defaults write com.apple.frameworks.diskimages skip-verify -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder WarnOnEmptyTrash -bool false
    chflags nohidden ~/Library
    sudo chflags nohidden /Users
    defaults write com.apple.finder FXInfoPanesExpanded -dict \
        General -bool true \
        OpenWith -bool true \
        Privileges -bool true
    success "Finder configured (list view, folders first, all bars visible)"
    ((CHANGES_MADE++))
    RESTART_FINDER=true
else
    if ask "Show all filename extensions?"; then
        defaults write NSGlobalDomain AppleShowAllExtensions -bool true
        success "All file extensions visible"
        ((CHANGES_MADE++))
        RESTART_FINDER=true
    fi

    if ask "Show toolbar, status bar, and path bar in Finder?"; then
        defaults write com.apple.finder ShowToolbar -bool true
        defaults write com.apple.finder ShowStatusBar -bool true
        defaults write com.apple.finder ShowPathbar -bool true
        success "Finder bars enabled"
        ((CHANGES_MADE++))
        RESTART_FINDER=true
    fi

    if ask "Keep folders on top when sorting by name?"; then
        defaults write com.apple.finder _FXSortFoldersFirst -bool true
        defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
        success "Folders sorted first"
        ((CHANGES_MADE++))
        RESTART_FINDER=true
    fi

    if ask "Display full POSIX path in Finder window title?"; then
        defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
        success "Full path in title bar"
        ((CHANGES_MADE++))
        RESTART_FINDER=true
    fi

    if ask "Search the current folder (not entire Mac) by default?"; then
        defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
        success "Search defaults to current folder"
        ((CHANGES_MADE++))
        RESTART_FINDER=true
    fi

    if ask "Disable the warning when changing a file extension?"; then
        defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
        success "Extension change warning disabled"
        ((CHANGES_MADE++))
        RESTART_FINDER=true
    fi

    if ask "Prevent .DS_Store files on network and USB volumes?"; then
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
        defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
        success ".DS_Store prevention enabled"
        ((CHANGES_MADE++))
    fi

    pick "Default Finder view?" "List view" "Icon view" "Column view" "Gallery view"
    views=("Nlsv" "icnv" "clmv" "Flwv")
    defaults write com.apple.finder FXPreferredViewStyle -string "${views[$((PICK_RESULT-1))]}"
    success "Finder view set"
    ((CHANGES_MADE++))
    RESTART_FINDER=true

    if ask "Show desktop icons for hard drives, servers, and removable media?"; then
        defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
        defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
        defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
        defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
        success "Desktop icons enabled"
        ((CHANGES_MADE++))
        RESTART_FINDER=true
    fi

    if ask "Show the ~/Library folder (hidden by default)?"; then
        chflags nohidden ~/Library
        success "~/Library visible"
        ((CHANGES_MADE++))
    fi

    if ask "Disable the warning before emptying the Trash?"; then
        defaults write com.apple.finder WarnOnEmptyTrash -bool false
        success "Trash warning disabled"
        ((CHANGES_MADE++))
        RESTART_FINDER=true
    fi
fi

###############################################################################
# Screenshots                                                                  #
###############################################################################

step "SCREENSHOTS"

if [[ "$MODE" == "express" ]]; then
    mkdir -p "${HOME}/Screenshots"
    defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
    defaults write com.apple.screencapture "include-date" -bool false
    defaults write com.apple.screencapture "name" -string "screenshot"
    defaults write com.apple.screencapture type -string "png"
    defaults write com.apple.screencapture show-thumbnail -bool false
    success "Screenshots → ~/Screenshots (PNG, no dates, no thumbnails)"
    ((CHANGES_MADE++))
else
    if ask "Save screenshots to ~/Screenshots instead of Desktop?"; then
        mkdir -p "${HOME}/Screenshots"
        defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
        success "Screenshots → ~/Screenshots"
        ((CHANGES_MADE++))
    fi

    pick "Screenshot format?" "PNG (lossless, larger)" "JPG (compressed, smaller)" "PDF" "TIFF"
    formats=("png" "jpg" "pdf" "tiff")
    defaults write com.apple.screencapture type -string "${formats[$((PICK_RESULT-1))]}"
    success "Screenshot format: ${formats[$((PICK_RESULT-1))]}"
    ((CHANGES_MADE++))

    if ask "Remove date/time from screenshot filenames?"; then
        defaults write com.apple.screencapture "include-date" -bool false
        defaults write com.apple.screencapture "name" -string "screenshot"
        success "Screenshot filenames simplified"
        ((CHANGES_MADE++))
    fi

    if ask "Disable the floating screenshot thumbnail preview?"; then
        defaults write com.apple.screencapture show-thumbnail -bool false
        success "Screenshot thumbnail disabled"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Dock                                                                         #
###############################################################################

step "DOCK"

if [[ "$MODE" == "express" ]]; then
    defaults write com.apple.dock no-bouncing -bool true
    defaults write com.apple.dock tilesize -int 16
    defaults write com.apple.dock magnification -bool false
    defaults write com.apple.dock show-process-indicators -bool false
    defaults write com.apple.dock persistent-apps -array ""
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock mru-spaces -bool false
    defaults write com.apple.dock showhidden -bool true
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 3
    defaults write com.apple.dock autohide-time-modifier -float 0.1
    defaults write com.apple.dock orientation -string "left"
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock mineffect -string "scale"
    success "Dock configured (auto-hide 3s delay, 16px, left side, empty)"
    ((CHANGES_MADE++))
    RESTART_DOCK=true
else
    if ask "Auto-hide the Dock?"; then
        defaults write com.apple.dock autohide -bool true
        RESTART_DOCK=true
        ((CHANGES_MADE++))

        pick "How long before the Dock appears on hover?" "3 seconds (practically invisible)" "1 second" "0.5 seconds (subtle)" "Instant (no delay)"
        case $PICK_RESULT in
            1) defaults write com.apple.dock autohide-delay -float 3 ;;
            2) defaults write com.apple.dock autohide-delay -float 1 ;;
            3) defaults write com.apple.dock autohide-delay -float 0.5 ;;
            4) defaults write com.apple.dock autohide-delay -float 0 ;;
        esac
        defaults write com.apple.dock autohide-time-modifier -float 0.1
        success "Dock auto-hide configured"
    fi

    pick "Dock icon size?" "16px (minimum — practically invisible)" "36px (small)" "48px (macOS default)" "64px (large)"
    case $PICK_RESULT in
        1) defaults write com.apple.dock tilesize -int 16 ;;
        2) defaults write com.apple.dock tilesize -int 36 ;;
        3) defaults write com.apple.dock tilesize -int 48 ;;
        4) defaults write com.apple.dock tilesize -int 64 ;;
    esac
    success "Dock icon size set"
    ((CHANGES_MADE++))
    RESTART_DOCK=true

    pick "Dock position?" "Left" "Bottom (default)" "Right"
    positions=("left" "bottom" "right")
    defaults write com.apple.dock orientation -string "${positions[$((PICK_RESULT-1))]}"
    success "Dock position: ${positions[$((PICK_RESULT-1))]}"
    ((CHANGES_MADE++))
    RESTART_DOCK=true

    if ask "Wipe all default app icons from the Dock (start clean)?"; then
        defaults write com.apple.dock persistent-apps -array ""
        success "Dock cleared"
        ((CHANGES_MADE++))
        RESTART_DOCK=true
    fi

    if ask "Remove recent apps section from the Dock?"; then
        defaults write com.apple.dock show-recents -bool false
        success "Recent apps removed from Dock"
        ((CHANGES_MADE++))
        RESTART_DOCK=true
    fi

    if ask "Disable icon bouncing in the Dock?"; then
        defaults write com.apple.dock no-bouncing -bool true
        success "Icon bouncing disabled"
        ((CHANGES_MADE++))
        RESTART_DOCK=true
    fi

    if ask "Minimize windows into their application icon?"; then
        defaults write com.apple.dock minimize-to-application -bool true
        defaults write com.apple.dock mineffect -string "scale"
        success "Minimize into app icon (scale effect)"
        ((CHANGES_MADE++))
        RESTART_DOCK=true
    fi

    if ask "Prevent Spaces from auto-rearranging based on recent use?"; then
        defaults write com.apple.dock mru-spaces -bool false
        success "Spaces order locked"
        ((CHANGES_MADE++))
        RESTART_DOCK=true
    fi
fi

###############################################################################
# Spotlight                                                                    #
###############################################################################

step "SPOTLIGHT"

if [[ "$MODE" == "express" ]]; then
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "{ enabled = 0; value = { parameters = (32, 49, 1048576); type = standard; }; }"
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "{ enabled = 0; value = { parameters = (32, 49, 1572864); type = standard; }; }"
    success "Spotlight shortcuts disabled"
    echo ""
    info "Launcher shortcuts to configure after first launch:"
    info "  Raycast  → Cmd+Space (Raycast sets this on first launch)"
    info "  Alfred   → Ctrl+Space (set manually in Alfred Preferences > General)"
    echo ""
    info "If Cmd+Space still triggers Spotlight after reboot:"
    info "  Go to System Settings > Keyboard > Keyboard Shortcuts > Spotlight"
    info "  Uncheck both Spotlight shortcuts"
    ((CHANGES_MADE++))
else
    if ask "Disable Spotlight keyboard shortcuts (to free Cmd+Space for Raycast/Alfred)?"; then
        defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "{ enabled = 0; value = { parameters = (32, 49, 1048576); type = standard; }; }"
        defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "{ enabled = 0; value = { parameters = (32, 49, 1572864); type = standard; }; }"
        success "Spotlight shortcuts disabled"
        echo ""
        info "Launcher shortcuts to configure after first launch:"
        info "  Raycast  → Cmd+Space (Raycast sets this on first launch)"
        info "  Alfred   → Ctrl+Space (set in Alfred Preferences > General)"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Login Items                                                                  #
###############################################################################

step "LOGIN ITEMS"

login_apps=(
    "/Applications/Alfred 5.app"
    "/Applications/Raycast.app"
    "/Applications/Rectangle.app"
)

if [[ "$MODE" == "express" ]]; then
    for app_path in "${login_apps[@]}"; do
        app_name=$(basename "$app_path" .app)
        if [[ -d "$app_path" ]]; then
            osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:true}" 2>/dev/null \
                && success "$app_name set to launch at login (hidden)" \
                || info "Could not add $app_name to login items"
        else
            info "$app_name not installed yet — add manually after install"
        fi
    done
    ((CHANGES_MADE++))
else
    for app_path in "${login_apps[@]}"; do
        app_name=$(basename "$app_path" .app)
        if [[ -d "$app_path" ]]; then
            if ask "Start $app_name automatically at login (hidden)?"; then
                osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:true}" 2>/dev/null \
                    && success "$app_name added to login items" \
                    || skip "Could not add $app_name"
                ((CHANGES_MADE++))
            fi
        else
            info "$app_name not installed — skipping"
        fi
    done
fi

###############################################################################
# Safari & WebKit                                                              #
###############################################################################

step "SAFARI"

# macOS Ventura+ sandboxes Safari preferences. Write to the container directly.
SAFARI_PLIST="$HOME/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist"

_safari_write() {
    if [[ -f "$SAFARI_PLIST" ]]; then
        /usr/libexec/PlistBuddy -c "Set :$1 $2" "$SAFARI_PLIST" &>/dev/null \
            || /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$SAFARI_PLIST" &>/dev/null
    else
        # Plist doesn't exist yet (Safari hasn't launched). Create it and write.
        mkdir -p "$(dirname "$SAFARI_PLIST")"
        /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$SAFARI_PLIST" &>/dev/null || true
    fi
}

if [[ "$MODE" == "express" ]]; then
    _safari_write IncludeInternalDebugMenu bool true
    _safari_write IncludeDevelopMenu bool true
    _safari_write WebKitDeveloperExtrasEnabledPreferenceKey bool true
    _safari_write "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" bool true
    success "Safari developer tools enabled"
    ((CHANGES_MADE++))
else
    if ask "Enable Safari Developer menu and Web Inspector?"; then
        _safari_write IncludeInternalDebugMenu bool true
        _safari_write IncludeDevelopMenu bool true
        _safari_write WebKitDeveloperExtrasEnabledPreferenceKey bool true
        _safari_write "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" bool true
        success "Safari developer tools enabled"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Time Machine                                                                 #
###############################################################################

step "TIME MACHINE"

if [[ "$MODE" == "express" ]]; then
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
    success "Time Machine drive prompt disabled"
    ((CHANGES_MADE++))
else
    if ask "Prevent Time Machine from prompting to use new drives as backup?"; then
        defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
        success "Time Machine drive prompt disabled"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Activity Monitor                                                             #
###############################################################################

step "ACTIVITY MONITOR"

if [[ "$MODE" == "express" ]]; then
    defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
    defaults write com.apple.ActivityMonitor IconType -int 5
    defaults write com.apple.ActivityMonitor ShowCategory -int 0
    defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    defaults write com.apple.ActivityMonitor SortDirection -int 0
    success "Activity Monitor configured"
    ((CHANGES_MADE++))
else
    if ask "Configure Activity Monitor (show all processes, CPU icon, sort by CPU)?"; then
        defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
        defaults write com.apple.ActivityMonitor IconType -int 5
        defaults write com.apple.ActivityMonitor ShowCategory -int 0
        defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
        defaults write com.apple.ActivityMonitor SortDirection -int 0
        success "Activity Monitor configured"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Messages                                                                     #
###############################################################################

step "MESSAGES"

if [[ "$MODE" == "express" ]]; then
    defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false
    defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false
    success "Messages smart text disabled"
    ((CHANGES_MADE++))
else
    if ask "Disable smart quotes and spell checking in Messages?"; then
        defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false
        defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false
        success "Messages smart text disabled"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# TextEdit                                                                     #
###############################################################################

step "TEXTEDIT"

if [[ "$MODE" == "express" ]]; then
    defaults write com.apple.TextEdit RichText -int 0
    defaults write com.apple.TextEdit PlainTextEncoding -int 4
    defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
    success "TextEdit: plain text / UTF-8"
    ((CHANGES_MADE++))
else
    if ask "Use plain text mode (UTF-8) by default in TextEdit?"; then
        defaults write com.apple.TextEdit RichText -int 0
        defaults write com.apple.TextEdit PlainTextEncoding -int 4
        defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
        success "TextEdit: plain text / UTF-8"
        ((CHANGES_MADE++))
    fi
fi

###############################################################################
# Apply changes                                                                #
###############################################################################

step "APPLYING CHANGES"

if [[ "$RESTART_DOCK" == true ]]; then
    killall "Dock" &>/dev/null || true
    success "Dock restarted"
fi

if [[ "$RESTART_FINDER" == true ]]; then
    killall "Finder" &>/dev/null || true
    success "Finder restarted"
fi

if [[ "$RESTART_SYSUI" == true ]]; then
    killall "SystemUIServer" &>/dev/null || true
    killall "ControlCenter" &>/dev/null || true
    success "Menu bar restarted"
fi

if [[ $CHANGES_MADE -gt 0 ]]; then
    killall "cfprefsd" &>/dev/null || true
    for app in "Activity Monitor" "Calendar" "Contacts" "Mail" "Messages" "Safari" "TextEdit"; do
        killall "${app}" &>/dev/null || true
    done
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                        All done!                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}$CHANGES_MADE${NC} settings configured."
echo ""
echo -e "${YELLOW}  ⚠ Some changes require a logout/restart to take effect.${NC}"
echo ""
