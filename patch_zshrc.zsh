#!/usr/bin/env zsh
# ============================================================
# DevCLI – Safe .zshrc Patcher
# Replaces any bare "source" lines for DevCLI files with
# guarded versions that CANNOT crash the shell.
# ============================================================

ZSHRC="$HOME/.zshrc"
[[ -f "$ZSHRC" ]] || touch "$ZSHRC"

# Back up .zshrc first
cp "$ZSHRC" "${ZSHRC}.devcli.bak"
echo "[devcli] Backed up ~/.zshrc to ~/.zshrc.devcli.bak"

# Replace raw source lines with guarded versions
# Pattern: source ~/.config/zsh/devcli.zsh-theme
#      →   [[ -f ~/.config/zsh/devcli.zsh-theme ]] && source ~/.config/zsh/devcli.zsh-theme 2>/dev/null || true

safe_source() {
  local file="$1"
  echo "[[ -f $file ]] && source $file 2>/dev/null || true"
}

# Rewrite the file in place
local tmpfile; tmpfile=$(mktemp)
while IFS= read -r line; do
  # Match bare: source ~/.config/zsh/devcli*
  if [[ "$line" =~ ^[[:space:]]*source[[:space:]]+~/.config/zsh/devcli ]]; then
    local path="${line##* }"   # extract path after 'source '
    echo "$(safe_source "$path")" >> "$tmpfile"
    echo "[devcli] Patched: $line"
  # Match bare: fastfetch (standalone on its own line)
  elif [[ "$line" =~ ^[[:space:]]*fastfetch[[:space:]]*$ ]]; then
    echo "command -v fastfetch &>/dev/null && fastfetch 2>/dev/null || true" >> "$tmpfile"
    echo "[devcli] Patched: fastfetch launch guard"
  else
    echo "$line" >> "$tmpfile"
  fi
done < "$ZSHRC"

mv "$tmpfile" "$ZSHRC"
echo "[devcli] ✔ ~/.zshrc patched with safe source guards"
echo ""
echo "To undo: cp ~/.zshrc.devcli.bak ~/.zshrc"
