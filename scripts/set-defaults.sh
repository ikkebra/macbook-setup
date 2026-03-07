#!/usr/bin/env bash
#
# set-defaults.sh — Configure macOS defaults for development
# Based on Ryan's original set-defaults.sh, enhanced with additional preferences.
#

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step()    { echo ""; echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

echo ""
warn "This will change macOS system settings."
echo "Close System Settings before continuing."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Ask for administrator password upfront
sudo -v

# Keep sudo alive until script completes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# Appearance                                                                   #
###############################################################################

step "Configuring appearance"

# Force dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Set accent color to blue (default)
defaults write NSGlobalDomain AppleAccentColor -int 4

# Set highlight color to blue
defaults write NSGlobalDomain AppleHighlightColor -string "0.698039 0.843137 1.000000 Blue"

success "Appearance configured (Dark Mode enabled)"

###############################################################################
# General UI/UX                                                                #
###############################################################################

step "Configuring general UI/UX settings"

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Set sidebar icon size to medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable Resume system-wide
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false

# Uncheck "Reopen windows when logging back in" on shutdown dialog
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Disable smart quotes as they're annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable smart dashes as they're annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

success "General settings configured"

###############################################################################
# Trackpad                                                                     #
###############################################################################

step "Configuring trackpad"

# Disable "natural" (inverted) scrolling — DOWN IS DOWN
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Enable three-finger drag (via Accessibility)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false

# Enable three-finger drag via accessibility preferences
defaults write com.apple.accessibility com.apple.Accessibility.DragLock.FeatureEnabled -bool true 2>/dev/null || true

success "Trackpad configured (natural scrolling OFF, three-finger drag ON)"

###############################################################################
# SSD-specific tweaks                                                          #
###############################################################################

step "Configuring SSD optimizations"

# Disable hibernation (speeds up entering sleep mode)
sudo pmset -a hibernatemode 0

# Disable the sudden motion sensor as it's not useful for SSDs
sudo pmset -a sms 0

success "SSD settings configured"

###############################################################################
# Keyboard and input                                                           #
###############################################################################

step "Configuring keyboard and input"

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set language and text formats
defaults write NSGlobalDomain AppleLanguages -array "en"
defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"
defaults write NSGlobalDomain AppleMetricUnits -bool false

# Set the timezone
systemsetup -settimezone "America/Boise" > /dev/null

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

success "Keyboard and input configured"

###############################################################################
# Screen                                                                       #
###############################################################################

step "Configuring screen settings"

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

success "Screen settings configured"

###############################################################################
# Finder                                                                       #
###############################################################################

step "Configuring Finder"

# Set Desktop as the default location for new Finder windows
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show toolbar
defaults write com.apple.finder ShowToolbar -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Keep folders on top on Desktop too
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true

# Finder: allow text selection in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Avoid creating .DS_Store files on USB volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Use column view in all Finder windows by default
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Users folder
sudo chflags nohidden /Users

# Expand the following File Info panes:
# "General", "Open with", and "Sharing & Permissions"
defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true

success "Finder configured"

###############################################################################
# Screenshots                                                                  #
###############################################################################

step "Configuring screenshots"

# Create Screenshots folder
mkdir -p "${HOME}/Screenshots"

# Save screenshots to ~/Screenshots
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# Exclude date and time in screenshot filenames
defaults write com.apple.screencapture "include-date" -bool false

# Change the default screenshot file name
defaults write com.apple.screencapture "name" -string "screenshot"

# Save screenshots as PNG (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable screenshot thumbnail preview (the floating thumbnail)
defaults write com.apple.screencapture show-thumbnail -bool false

success "Screenshot settings configured (saving to ~/Screenshots)"

###############################################################################
# Dock — Make it as invisible as possible                                      #
###############################################################################

step "Configuring Dock (hiding it as much as possible)"

# Prevent applications from bouncing in Dock
defaults write com.apple.dock no-bouncing -bool true

# Set the icon size to minimum (16 pixels)
defaults write com.apple.dock tilesize -int 16

# Enable magnification but keep it small
defaults write com.apple.dock magnification -bool false

# Hide indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool false

# Wipe all (default) app icons from the Dock
defaults write com.apple.dock persistent-apps -array ""

# Remove all recent apps from Dock
defaults write com.apple.dock show-recents -bool false

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Enable auto-hide
defaults write com.apple.dock autohide -bool true

# Set a very long auto-hide delay (3 seconds before it appears)
defaults write com.apple.dock autohide-delay -float 3

# Speed up the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0.1

# Position Dock on the left side (takes less screen real estate when it does show)
defaults write com.apple.dock orientation -string "left"

# Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true

# Minimize using scale effect (faster than genie)
defaults write com.apple.dock mineffect -string "scale"

success "Dock configured (auto-hide with 3s delay, 16px icons, left side)"

###############################################################################
# Spotlight — Disable shortcut (Alfred/Raycast will use Cmd+Space)            #
###############################################################################

step "Configuring Spotlight"

# Note: Disabling the Spotlight shortcut via defaults is unreliable on newer macOS.
# The most reliable method is through System Settings > Keyboard > Shortcuts > Spotlight.
# We'll try the defaults approach, but you may need to do this manually.

# Disable Spotlight keyboard shortcut (Cmd+Space) so Alfred can use it
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "{ enabled = 0; value = { parameters = (32, 49, 1048576); type = standard; }; }"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "{ enabled = 0; value = { parameters = (32, 49, 1572864); type = standard; }; }"

warn "If Cmd+Space still triggers Spotlight after reboot:"
echo "  Go to System Settings > Keyboard > Keyboard Shortcuts > Spotlight"
echo "  Uncheck both Spotlight shortcuts, then set Alfred to Cmd+Space"

success "Spotlight shortcuts disabled"

###############################################################################
# Safari & WebKit                                                              #
###############################################################################

step "Configuring Safari"

# Enable Safari's debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

success "Safari configured"

###############################################################################
# Time Machine                                                                 #
###############################################################################

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Activity Monitor                                                             #
###############################################################################

step "Configuring Activity Monitor"

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

success "Activity Monitor configured"

###############################################################################
# Messages                                                                     #
###############################################################################

step "Configuring Messages"

# Disable smart quotes in Messages
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

# Disable continuous spell checking in Messages
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false

success "Messages configured"

###############################################################################
# TextEdit                                                                     #
###############################################################################

step "Configuring TextEdit"

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

success "TextEdit configured"

###############################################################################
# Apply changes                                                                #
###############################################################################

step "Restarting affected applications"

for app in "Activity Monitor" "Calendar" "Contacts" "cfprefsd" \
    "Dock" "Finder" "Mail" "Messages" "Safari" "SystemUIServer" \
    "TextEdit"; do
    killall "${app}" &> /dev/null || true
done

echo ""
success "macOS defaults configured!"
echo ""
warn "Some changes require a logout/restart to take effect."
echo ""
