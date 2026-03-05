#!/usr/bin/env zsh
# ============================================================
# DevCLI – macOS Terminal Theme Installer
# ============================================================
# Usage: ./install.sh
# ============================================================

set -e

SCRIPT_DIR="${0:A:h}"
SRC_DIR="$SCRIPT_DIR/src"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'
YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo "${CYAN}[devcli]${RESET} $*" }
success() { echo "${GREEN}[✔]${RESET} $*" }
warn()    { echo "${YELLOW}[!]${RESET} $*" }
error()   { echo "${RED}[✘]${RESET} $*" >&2 }

print_banner() {
cat <<'EOF'

  ____  _         ____ _     ___ 
 |  _ \| |__ __ _/ ___| |   |_ _|
 | | | | / _ \ \ / /   | |    | | 
 | |_| |  __/\ V / /___| |___ | | 
 |____/ \___| \_/ \____|_____|___|

  Linux-style terminal theme for macOS
  ──────────────────────────────────────
EOF
}

# ── 1. Install Terminal.app profiles (silent — no new windows) ─
install_terminal_profile() {
  info "Importing DevCLI profiles into Terminal.app…"

  local importer="$SCRIPT_DIR/import_profiles.py"

  if [[ ! -f "$importer" ]]; then
    warn "import_profiles.py not found — skipping profile install."
    warn "Run: python3 $SCRIPT_DIR/import_profiles.py"
    return 0
  fi

  if ! python3 "$importer"; then
    warn "Profile import had issues. Run manually:"
    warn "  python3 $importer"
    return 0
  fi

  success "All DevCLI profiles imported (no new windows opened)"
  info "To switch theme on the CURRENT window:"
  info "  Shell menu → Use Profile → pick a DevCLI theme"
}


# ── 2. Install Zsh Theme ────────────────────────────────────
install_zsh_theme() {
  info "Installing Zsh theme…"

  local theme_src="$SRC_DIR/devcli.zsh-theme"
  local zshrc="$HOME/.zshrc"

  local omz_themes="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"
  local installed_via_omz=false

  if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}" ]]; then
    mkdir -p "$omz_themes"
    cp "$theme_src" "$omz_themes/devcli.zsh-theme"
    success "Copied theme to Oh My Zsh custom themes: $omz_themes"
    if grep -q 'ZSH_THEME=' "$zshrc" 2>/dev/null; then
      sed -i '' 's/ZSH_THEME=.*/ZSH_THEME="devcli"/' "$zshrc"
    else
      echo 'ZSH_THEME="devcli"' >> "$zshrc"
    fi
    success "Set ZSH_THEME=\"devcli\" in $zshrc"
    installed_via_omz=true
  fi

  if [[ "$installed_via_omz" == false ]]; then
    local dest="$HOME/.config/zsh/devcli.zsh-theme"
    mkdir -p "$HOME/.config/zsh"
    cp "$theme_src" "$dest"
    success "Copied theme to $dest"
    local source_line="source ~/.config/zsh/devcli.zsh-theme"
    if ! grep -qF "$source_line" "$zshrc" 2>/dev/null; then
      echo "" >> "$zshrc"
      echo "# DevCLI Theme" >> "$zshrc"
      echo "$source_line" >> "$zshrc"
      success "Added source line to $zshrc"
    fi
  fi
}

# ── 3. Install Fastfetch ────────────────────────────────────
install_fastfetch() {
  info "Setting up fastfetch…"

  local ff_config_dir="$HOME/.config/fastfetch"
  local ff_config_src="$SRC_DIR/fastfetch.jsonc"

  if ! command -v fastfetch &>/dev/null; then
    if command -v brew &>/dev/null; then
      info "Installing fastfetch via Homebrew…"
      brew install fastfetch
      success "fastfetch installed"
    else
      warn "Homebrew not found. Install fastfetch manually: https://github.com/fastfetch-cli/fastfetch"
      return 0
    fi
  fi

  mkdir -p "$ff_config_dir"
  [[ -f "$ff_config_dir/config.jsonc" ]] && cp "$ff_config_dir/config.jsonc" "$ff_config_dir/config.jsonc.bak"
  cp "$ff_config_src" "$ff_config_dir/config.jsonc"
  success "fastfetch config installed to $ff_config_dir/config.jsonc"

  local zshrc="$HOME/.zshrc"
  if ! grep -qF "fastfetch" "$zshrc" 2>/dev/null; then
    read -q "REPLY?Add fastfetch to show on terminal launch? [y/N] "
    echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      echo "" >> "$zshrc"
      echo "# DevCLI – Show system info on launch" >> "$zshrc"
      echo "fastfetch" >> "$zshrc"
      success "Added fastfetch to $zshrc"
    fi
  else
    info "fastfetch already in $zshrc"
  fi
}

# ── 4. Install Custom Commands ──────────────────────────────
install_commands() {
  info "Installing DevCLI custom commands…"

  local cmd_src="$SRC_DIR/devcli_commands.zsh"
  local cmd_dest="$HOME/.config/zsh/devcli_commands.zsh"
  local zshrc="$HOME/.zshrc"

  mkdir -p "$HOME/.config/zsh"
  cp "$cmd_src" "$cmd_dest"
  success "Copied commands to $cmd_dest"

  local source_line="source ~/.config/zsh/devcli_commands.zsh"
  if ! grep -qF "$source_line" "$zshrc" 2>/dev/null; then
    echo "" >> "$zshrc"
    echo "# DevCLI Custom Commands" >> "$zshrc"
    echo "$source_line" >> "$zshrc"
    success "Added commands source line to $zshrc"
  else
    info "Commands already wired into $zshrc"
  fi
}

# ── Main ───────────────────────────────────────────────────
main() {
  print_banner
  echo ""
  install_terminal_profile
  echo ""
  install_zsh_theme
  echo ""
  install_fastfetch
  echo ""
  install_commands
  echo ""

  success "${BOLD}DevCLI installed!${RESET}"
  echo ""
  info "Open a new terminal window to see the changes."
  info "Run ${CYAN}fastfetch${RESET}  — system info panel"
  info "Run ${CYAN}devcli${RESET}     — list all DevCLI commands"
}

main "$@"
