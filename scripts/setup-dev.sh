#!/usr/bin/env bash
#
# setup-dev.sh — Configure SSH, Git, VS Code, and Composer
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
# SSH Key                                                                      #
###############################################################################

step "Setting up SSH key"

SSH_KEY="$HOME/.ssh/id_ed25519"

if [[ -f "$SSH_KEY" ]]; then
    success "SSH key already exists"
else
    echo "Generating new Ed25519 SSH key..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "github@ikkebra.com" -f "$SSH_KEY" -N ""

    # Start ssh-agent and add key
    eval "$(ssh-agent -s)"

    # Create SSH config to auto-load key
    if [[ ! -f "$HOME/.ssh/config" ]]; then
        cat > "$HOME/.ssh/config" << 'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
EOF
    fi

    ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY"

    success "SSH key generated"
    echo ""
fi

###############################################################################
# GitHub CLI Authentication                                                    #
###############################################################################

step "GitHub authentication"

if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null; then
        success "Already authenticated with GitHub CLI"
    else
        echo ""
        echo "  Let's authenticate with GitHub and upload your SSH key."
        echo ""
        read -p "  Authenticate with GitHub now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh auth login -p ssh -h github.com -w
            echo ""

            # Upload SSH key to GitHub
            if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
                echo "  Uploading SSH key to GitHub..."
                gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "MacBook Pro M4 Max" 2>/dev/null \
                    && success "SSH key added to GitHub" \
                    || warn "SSH key may already exist on GitHub"
            fi
        else
            warn "Skipped GitHub auth. Run these later:"
            echo "  gh auth login"
            echo "  gh ssh-key add ~/.ssh/id_ed25519.pub --title \"MacBook Pro M4 Max\""
        fi
    fi
else
    warn "GitHub CLI not installed — run install-apps.sh first"
fi

###############################################################################
# Git Configuration                                                            #
###############################################################################

step "Configuring Git"

git config --global user.name "Ryan"
git config --global user.email "github@ikkebra.com"

# Default branch name
git config --global init.defaultBranch main

# Pull strategy
git config --global pull.rebase false

# Push strategy
git config --global push.autoSetupRemote true

# Editor
git config --global core.editor "code --wait"

# Diff tool
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'

# Merge tool
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'

# Useful aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.last 'log -1 HEAD'
git config --global alias.lg "log --oneline --graph --decorate --all -20"
git config --global alias.undo 'reset HEAD~1 --mixed'
git config --global alias.amend 'commit --amend --no-edit'

# Colors
git config --global color.ui auto

# Ignore .DS_Store globally
GITIGNORE_GLOBAL="$HOME/.gitignore_global"
if [[ ! -f "$GITIGNORE_GLOBAL" ]]; then
    cat > "$GITIGNORE_GLOBAL" << 'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride
._*
.Spotlight-V100
.Trashes

# IDEs
.idea/
.vscode/
*.swp
*.swo
*~

# Environment
.env.local
.env.*.local
EOF
    git config --global core.excludesFile "$GITIGNORE_GLOBAL"
    success "Global gitignore created"
fi

success "Git configured"

###############################################################################
# VS Code Extensions                                                           #
###############################################################################

step "Installing VS Code extensions"

if command -v code &>/dev/null; then

    extensions=(
        # PHP / Laravel
        "bmewburn.vscode-intelephense-client"     # PHP Intelephense
        "onecentlin.laravel-blade"                 # Laravel Blade Snippets
        "onecentlin.laravel5-snippets"             # Laravel Snippets
        "amiralizadeh9480.laravel-extra-intellisense"  # Laravel Extra Intellisense
        "shufo.vscode-blade-formatter"             # Blade Formatter
        "codingyu.laravel-goto-view"               # Laravel Goto View
        "mikestead.dotenv"                         # DotENV syntax
        "neilbrayfield.php-docblocker"             # PHP DocBlocker

        # Git
        "eamodio.gitlens"                          # GitLens — supercharge Git
        "mhutchie.git-graph"                       # Git Graph — visual branch history

        # Editor Enhancement
        "EditorConfig.EditorConfig"                # EditorConfig support
        "esbenp.prettier-vscode"                   # Prettier formatter
        "streetsidesoftware.code-spell-checker"    # Spell checking for code
        "christian-kohler.path-intellisense"       # Path autocomplete
        "formulahendry.auto-rename-tag"            # Auto rename paired HTML/Blade tags
        "formulahendry.auto-close-tag"             # Auto close HTML/Blade tags

        # Theme & Icons
        "PKief.material-icon-theme"                # Material icon theme
        "GitHub.github-vscode-theme"               # GitHub theme

        # Utilities
        "ms-azuretools.vscode-docker"              # Docker support (if ever needed)
        "yzhang.markdown-all-in-one"               # Markdown support
        "mechatroner.rainbow-csv"                  # Rainbow CSV columns
        "humao.rest-client"                        # REST client (alternative to Postman)
    )

    for ext in "${extensions[@]}"; do
        # Skip comments
        [[ "$ext" =~ ^#.* ]] && continue
        echo "  Installing ${ext}..."
        code --install-extension "$ext" --force 2>/dev/null || warn "Failed to install ${ext}"
    done

    success "VS Code extensions installed"
else
    warn "VS Code CLI 'code' not found — install VS Code first"
    warn "After installing VS Code, run: Shell Command: Install 'code' command in PATH"
fi

###############################################################################
# VS Code Settings                                                             #
###############################################################################

step "Configuring VS Code settings"

VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSCODE_SETTINGS_DIR"

SETTINGS_FILE="${VSCODE_SETTINGS_DIR}/settings.json"

# Only write if no settings exist yet (don't overwrite existing config)
if [[ ! -f "$SETTINGS_FILE" ]] || [[ ! -s "$SETTINGS_FILE" ]] || [[ "$(cat "$SETTINGS_FILE")" == "{}" ]]; then
    cat > "$SETTINGS_FILE" << 'EOF'
{
    // Editor
    "editor.fontFamily": "MesloLGS NF, Menlo, Monaco, 'Courier New', monospace",
    "editor.fontSize": 14,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.wordWrap": "off",
    "editor.minimap.enabled": false,
    "editor.renderWhitespace": "boundary",
    "editor.suggestSelection": "first",
    "editor.formatOnSave": false,
    "editor.linkedEditing": true,
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": "active",
    "editor.smoothScrolling": true,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",

    // Theme
    "workbench.colorTheme": "GitHub Dark Default",
    "workbench.iconTheme": "material-icon-theme",
    "workbench.startupEditor": "none",
    "workbench.tree.indent": 16,

    // Terminal
    "terminal.integrated.fontFamily": "MesloLGS NF",
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.defaultProfile.osx": "zsh",

    // Files
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.trimFinalNewlines": true,
    "files.exclude": {
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/vendor": true
    },

    // PHP / Laravel
    "php.validate.enable": false,
    "intelephense.files.maxSize": 5000000,
    "intelephense.environment.phpVersion": "8.4.0",
    "[php]": {
        "editor.defaultFormatter": "bmewburn.vscode-intelephense-client",
        "editor.tabSize": 4
    },
    "[blade]": {
        "editor.defaultFormatter": "shufo.vscode-blade-formatter",
        "editor.tabSize": 4
    },

    // Emmet for Blade
    "emmet.includeLanguages": {
        "blade": "html"
    },

    // Git
    "git.autofetch": true,
    "git.confirmSync": false,
    "git.enableSmartCommit": true,

    // Spell checker
    "cSpell.userWords": [
        "artisan", "Laravel", "Eloquent", "Livewire", "Filament",
        "middleware", "Tailwind", "Inertia", "sanctum", "ploi"
    ],

    // Explorer
    "explorer.confirmDragAndDrop": false,
    "explorer.confirmDelete": false,
    "explorer.compactFolders": false,

    // Telemetry
    "telemetry.telemetryLevel": "off"
}
EOF
    success "VS Code settings configured"
else
    warn "VS Code settings already exist — not overwriting"
fi

###############################################################################
# Composer Configuration                                                       #
###############################################################################

step "Configuring Composer"

if command -v composer &>/dev/null; then
    # Set Composer home if not set
    export COMPOSER_HOME="${COMPOSER_HOME:-$HOME/.composer}"
    mkdir -p "$COMPOSER_HOME"

    # Install global Composer packages
    step "Installing global Composer packages"

    composer global require laravel/installer 2>/dev/null || warn "laravel/installer skipped (may need Herd PHP first)"
    composer global require laravel/pint 2>/dev/null || warn "laravel/pint skipped"

    success "Composer configured (home: $COMPOSER_HOME)"
    success "Global packages: laravel/installer, laravel/pint"

    echo ""
    warn "Per-project packages to remember (composer require --dev):"
    echo "  laravel/telescope   — Debug dashboard"
    echo "  echolabsdev/prism   — Unified LLM integration"
    echo "  laravel/pint        — Code style fixer (also installed globally)"
    echo ""
    warn "Per-project Laravel + Claude Code setup:"
    echo "  php artisan boost:install  — Laravel Boost (MCP server for Claude Code)"
    echo "  Adds: schema inspection, route queries, artisan commands, Laravel docs search"
else
    warn "Composer not found — it will be available after Herd is installed"
fi

###############################################################################
# Claude Code Configuration (optional)                                         #
###############################################################################

step "Claude Code configuration"

CLAUDE_DIR="$HOME/.claude"

if [[ -d "$CLAUDE_DIR" ]] && [[ -d "$CLAUDE_DIR/agents" ]]; then
    success "Claude Code config already installed"
else
    echo ""
    echo "  Install Claude Code config? (agents, skills, pre-approved commands)"
    echo "  Repo: github.com/ikkebra/claude-config"
    echo ""
    read -p "  Install Claude Code config? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Back up existing config
        if [[ -d "$CLAUDE_DIR" ]]; then
            cp -r "$CLAUDE_DIR" "${CLAUDE_DIR}.bak"
            warn "Existing ~/.claude backed up to ~/.claude.bak"
        fi

        mkdir -p "$CLAUDE_DIR"

        # Clone and install
        TEMP_DIR=$(mktemp -d)
        git clone git@github.com:ikkebra/claude-config.git "$TEMP_DIR" 2>/dev/null \
            || git clone https://github.com/ikkebra/claude-config.git "$TEMP_DIR"

        cp -r "$TEMP_DIR"/* "$CLAUDE_DIR/"
        cp -r "$TEMP_DIR"/.* "$CLAUDE_DIR/" 2>/dev/null || true
        rm -rf "$TEMP_DIR"

        # Make statusline executable
        [[ -f "$CLAUDE_DIR/statusline.sh" ]] && chmod +x "$CLAUDE_DIR/statusline.sh"

        success "Claude Code config installed"
        echo ""
        echo "  Includes:"
        echo "    Agents:  laravel-debugger, laravel-simplifier, laravel-feature-builder, task-planner"
        echo "    Skills:  agent-browser, ray-skill, context7, Spatie PHP guidelines, and more"
        echo "    Config:  pre-approved commands, extended thinking, high effort"
    else
        skip "Skipped Claude Code config"
    fi
fi

###############################################################################
# Create common dev directories                                                #
###############################################################################

step "Creating development directories"

mkdir -p "$HOME/dev"
mkdir -p "$HOME/Screenshots"

success "~/dev directory created"
success "~/Screenshots directory created"

echo ""
success "Development environment configured!"
echo ""
