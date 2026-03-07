#!/usr/bin/env bash
#
# setup-file-defaults.sh — Set default applications for file types using duti
#
# duti uses UTI (Uniform Type Identifier) strings to map file types to apps.
# Format: duti -s <bundle_id> <UTI_or_extension> <role>
# Roles: all, viewer, editor, shell, none
#

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step()    { echo ""; echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }

# Check for duti
if ! command -v duti &>/dev/null; then
    warn "duti is not installed. Install it with: brew install duti"
    exit 1
fi

###############################################################################
# VLC — Default for all media files                                            #
###############################################################################

step "Setting VLC as default media player"

VLC_BUNDLE="org.videolan.vlc"

# Video formats
video_types=(
    "public.avi"
    "public.mpeg-4"
    "com.apple.quicktime-movie"
    "public.movie"
    "public.3gpp"
    "public.3gpp2"
    "org.matroska.mkv"
    "com.microsoft.windows-media-wmv"
    "public.mpeg"
    "public.mpeg-2-video"
)

video_extensions=(
    ".mp4"
    ".avi"
    ".mkv"
    ".mov"
    ".wmv"
    ".flv"
    ".webm"
    ".m4v"
    ".mpg"
    ".mpeg"
    ".3gp"
    ".ts"
    ".vob"
)

# Audio formats
audio_extensions=(
    ".mp3"
    ".flac"
    ".aac"
    ".ogg"
    ".wav"
    ".wma"
    ".m4a"
    ".opus"
    ".aiff"
)

# Set VLC for video UTIs
for uti in "${video_types[@]}"; do
    duti -s "$VLC_BUNDLE" "$uti" viewer 2>/dev/null || true
done

# Set VLC for video extensions
for ext in "${video_extensions[@]}"; do
    duti -s "$VLC_BUNDLE" "$ext" all 2>/dev/null || true
done

# Set VLC for audio extensions
for ext in "${audio_extensions[@]}"; do
    duti -s "$VLC_BUNDLE" "$ext" all 2>/dev/null || true
done

success "VLC set as default for video and audio files"

###############################################################################
# VS Code — Default for code/text files                                        #
###############################################################################

step "Setting VS Code as default code editor"

VSCODE_BUNDLE="com.microsoft.VSCode"

code_extensions=(
    ".txt"
    ".md"
    ".json"
    ".xml"
    ".yaml"
    ".yml"
    ".toml"
    ".ini"
    ".cfg"
    ".conf"
    ".env"
    ".sh"
    ".bash"
    ".zsh"
    ".fish"
    ".py"
    ".rb"
    ".js"
    ".ts"
    ".jsx"
    ".tsx"
    ".css"
    ".scss"
    ".less"
    ".html"
    ".htm"
    ".php"
    ".blade.php"
    ".vue"
    ".svelte"
    ".sql"
    ".log"
    ".csv"
    ".svg"
    ".gitignore"
    ".editorconfig"
    ".prettierrc"
    ".eslintrc"
)

for ext in "${code_extensions[@]}"; do
    duti -s "$VSCODE_BUNDLE" "$ext" editor 2>/dev/null || true
done

# Also set VS Code for public.plain-text UTI
duti -s "$VSCODE_BUNDLE" "public.plain-text" editor 2>/dev/null || true
duti -s "$VSCODE_BUNDLE" "public.json" editor 2>/dev/null || true
duti -s "$VSCODE_BUNDLE" "public.shell-script" editor 2>/dev/null || true
duti -s "$VSCODE_BUNDLE" "public.python-script" editor 2>/dev/null || true
duti -s "$VSCODE_BUNDLE" "public.php-script" editor 2>/dev/null || true
duti -s "$VSCODE_BUNDLE" "public.xml" editor 2>/dev/null || true
duti -s "$VSCODE_BUNDLE" "public.yaml" editor 2>/dev/null || true

success "VS Code set as default for code and text files"

###############################################################################
# Brave — Default browser                                                      #
###############################################################################

step "Setting Brave as default browser"

# Note: Setting default browser via command line is limited on modern macOS.
# The OS usually prompts the user. But we can try:
BRAVE_BUNDLE="com.brave.Browser"

duti -s "$BRAVE_BUNDLE" "public.html" viewer 2>/dev/null || true
duti -s "$BRAVE_BUNDLE" "public.xhtml" viewer 2>/dev/null || true
duti -s "$BRAVE_BUNDLE" "public.url" viewer 2>/dev/null || true

warn "macOS may prompt you to confirm Brave as default browser on first launch"

success "File associations configured"

echo ""
success "Default applications configured!"
echo "  Media (video/audio) → VLC"
echo "  Code/text files → VS Code"
echo "  Web content → Brave"
echo ""
