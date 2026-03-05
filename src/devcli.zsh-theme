#!/usr/bin/env zsh
# ============================================================
# DevCLI Zsh Theme — Crash-hardened
# ============================================================
# Every function is wrapped so that a bug here NEVER breaks
# an interactive shell session.
#
# Prompt:
#   ┌──(user㉿hostname)-[~/current/dir]
#   └─$

# Run in a clean Zsh environment for predictability
emulate -L zsh 2>/dev/null

# ── Colours ──────────────────────────────────────────────────
_DC_RESET="%{%f%b%k%}"
_DC_CYAN="%{%F{cyan}%}"
_DC_GREEN="%{%F{green}%}"
_DC_WHITE="%{%F{white}%}"
_DC_BLUE="%{%F{blue}%}"
_DC_RED="%{%F{red}%}"
_DC_BOLD="%{%B%}"

# ── Git branch (silent — never throws) ───────────────────────
_devcli_git_branch() {
  {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) ||
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return 0
    if git status --porcelain 2>/dev/null | grep -q .; then
      print -n " ${_DC_RED}git:(${branch}✗)${_DC_RESET}"
    else
      print -n " ${_DC_GREEN}git:(${branch})${_DC_RESET}"
    fi
  } 2>/dev/null
}

# ── Prompt builder ────────────────────────────────────────────
_devcli_build_prompt() {
  # Isolate in subshell so any error cannot break the caller
  {
    local exit_code=$?
    local git_info
    git_info=$(_devcli_git_branch 2>/dev/null)

    local dollar_color="${_DC_GREEN}"
    [[ $exit_code -ne 0 ]] && dollar_color="${_DC_RED}"

    PROMPT="${_DC_GREEN}┌──(${_DC_RESET}${_DC_BOLD}${_DC_CYAN}%n${_DC_RESET}${_DC_WHITE}㉿${_DC_RESET}${_DC_BOLD}${_DC_CYAN}%m${_DC_RESET}${_DC_GREEN})-[${_DC_RESET}${_DC_BOLD}${_DC_BLUE}%~${_DC_RESET}${_DC_GREEN}]${_DC_RESET}${git_info}
${_DC_GREEN}└─${_DC_RESET}${dollar_color}${_DC_BOLD}\$${_DC_RESET} "

    RPROMPT="${_DC_WHITE}%T${_DC_RESET}"
  } 2>/dev/null || {
    # Emergency fallback — plain prompt if everything goes wrong
    PROMPT="%n@%m %~ \$ "
    RPROMPT=""
  }
}

# Register hook — if it fails, we still get a shell
if (( ${+precmd_functions} )); then
  precmd_functions+=(_devcli_build_prompt)
else
  precmd_functions=(_devcli_build_prompt)
fi

# Build once immediately
_devcli_build_prompt
