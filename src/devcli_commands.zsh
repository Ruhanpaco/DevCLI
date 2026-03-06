#!/usr/bin/env zsh
# ============================================================
# DevCLI Custom Commands  — Crash-hardened edition
# Source this file in ~/.zshrc or let install.sh do it.
# ============================================================

# IMPORTANT: disable errexit so a bug here never kills the shell
setopt local_options 2>/dev/null
set +e

# ── Version ───────────────────────────────────────────────────
DEVCLI_VERSION="1.0.1"
DEVCLI_REPO="Ruhanpaco/DevCLI"
DEVCLI_UPDATE_CACHE="${HOME}/.cache/devcli_update_check"

# ── Colour helpers ────────────────────────────────────────────
_NS_C='\033[0;36m'     # cyan  (keys)
_NS_BC='\033[0;96m'    # bright cyan (headers)
_NS_G='\033[0;32m'     # green
_NS_Y='\033[1;33m'     # yellow
_NS_R='\033[0;31m'     # red
_NS_W='\033[1;37m'     # white
_NS_D='\033[2;37m'     # dim
_NS_X='\033[0m'        # reset

_ns_header() {
  echo ""
  echo "${_NS_BC}╔══════════════════════════════════════╗${_NS_X}"
  printf  "${_NS_BC}║  %-36s║${_NS_X}\n" "$1"
  echo "${_NS_BC}╚══════════════════════════════════════╝${_NS_X}"
}

_ns_row() {
  printf "  ${_NS_C}%-18s${_NS_X} ${_NS_W}%s${_NS_X}\n" "$1" "$2"
}

# Draw a 20-char usage bar — crash-safe
_ns_bar() {
  local raw="${1//[^0-9]/}"    # strip anything that isn't a digit
  [[ -z "$raw" ]] && raw=0     # guard against empty input
  local pct=$(( raw > 100 ? 100 : raw )) 2>/dev/null || pct=0
  local filled=$(( pct / 5 ))  2>/dev/null || filled=0
  local empty=$(( 20 - filled )) 2>/dev/null || empty=20
  local col="${_NS_G}"
  (( pct >= 70 )) && col="${_NS_Y}"
  (( pct >= 90 )) && col="${_NS_R}"
  printf "%s[" "$col"
  local i
  for (( i=0; i<filled; i++ )); do printf '█'; done
  printf "%s" "${_NS_D}"
  for (( i=0; i<empty;  i++ )); do printf '░'; done
  printf "%s] %s%s%%%s" "$col" "${_NS_W}" "$pct" "${_NS_X}"
}

# ── Helper: get current CPU % ─────────────────────────────────
_cpu_pct() {
  top -l 2 -n 0 2>/dev/null | awk -F'[:,% ]+' \
    '/CPU usage/{usr=$2; sys=$4; print int(usr+sys)}' | tail -1
}

# ── Helper: get WiFi SSID reliably ───────────────────────────
_wifi_ssid() {
  # Try airport utility first
  local airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  if [[ -x "$airport" ]]; then
    local ssid
    ssid=$("$airport" -I 2>/dev/null | awk -F': ' '/ SSID/{gsub(/^ +/,"",$2); print $2}')
    [[ -n "$ssid" && "$ssid" != " " ]] && { echo "$ssid"; return; }
  fi
  # Fall back to networksetup
  local ns
  ns=$(networksetup -getairportnetwork en0 2>/dev/null)
  if [[ "$ns" == *"You are not associated"* ]] || [[ -z "$ns" ]]; then
    echo "Not connected"
  else
    echo "${ns#*: }"
  fi
}

# ────────────────────────────────────────────────────────────
# sysinfo — snapshot system overview
# ────────────────────────────────────────────────────────────
sysinfo() {
  _ns_header "⚡  SYSTEM INFO"

  local os kernel uptime cpu gpu ram_total ram_pct cpu_pct

  os="$(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null)"
  kernel=$(uname -r)
  uptime=$(uptime | sed 's/.*up //' | sed 's/, [0-9]* user.*//')
  cpu=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || \
        system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip/{print $2}')
  gpu=$(system_profiler SPDisplaysDataType 2>/dev/null | \
        awk -F': ' '/Chipset Model|GPU name/{gsub(/^ /,"",$2); print $2; exit}')
  ram_total=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
  ram_pct=$(memory_pressure 2>/dev/null | \
            awk '/System-wide memory free percentage/{pct=$NF+0} END{printf "%d",100-pct}')
  local ram_used=$(( ram_pct * ram_total / 100 ))
  cpu_pct=$(_cpu_pct)

  _ns_row "OS"       "$os"
  _ns_row "Kernel"   "$kernel"
  _ns_row "Uptime"   "$uptime"
  _ns_row "CPU"      "$cpu"
  _ns_row "GPU"      "${gpu:-Integrated}"
  printf  "  ${_NS_C}%-18s${_NS_X} " "CPU Usage"
  _ns_bar "${cpu_pct:-0}"
  printf  "  ${_NS_W}(${cpu_pct:-0}%%)${_NS_X}\n"
  printf  "  ${_NS_C}%-18s${_NS_X} " "RAM Usage"
  _ns_bar "${ram_pct:-0}"
  printf  "  ${_NS_W}(${ram_used}/${ram_total} GiB)${_NS_X}\n"
  _ns_row "Shell"    "$SHELL ($ZSH_VERSION)"
  _ns_row "Hostname" "$(hostname)"
  echo ""
}

# ────────────────────────────────────────────────────────────
# syswatch — LIVE real-time dashboard (Ctrl+C to exit)
# ────────────────────────────────────────────────────────────
syswatch() {
  local interval=${1:-2}

  # ── Terminal cleanup function — called on ANY exit ──────
  _syswatch_cleanup() {
    tput cnorm    2>/dev/null  # restore cursor
    tput rmcup    2>/dev/null  # restore original screen buffer
    printf '%b' "${_NS_X}"    # reset colours
    # Clear the trap so it won't fire again
    trap - INT TERM EXIT HUP
  }

  # Register cleanup for every possible exit signal
  trap '_syswatch_cleanup; return 0' INT TERM EXIT HUP

  # Switch to alternate screen buffer (preserves scrollback)
  tput smcup    2>/dev/null
  tput civis    2>/dev/null  # hide cursor
  clear

  while true; do
    # ── Gather metrics ──────────────────────────────────────
    local cpu_pct ram_pct batt_pct batt_status
    local ram_total ram_used load net_ssid

    cpu_pct=$(top -l 2 -n 0 2>/dev/null | \
      awk -F'[:,% ]+' '/CPU usage/{usr=$2; sys=$4; print int(usr+sys)}' 2>/dev/null | tail -1) || cpu_pct=0
    [[ -z "$cpu_pct" ]] && cpu_pct=0
    ram_total=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 )) 2>/dev/null || ram_total=0
    ram_pct=$(memory_pressure 2>/dev/null | \
      awk '/free percentage/{pct=$NF+0} END{printf "%d",100-pct}' 2>/dev/null) || ram_pct=0
    [[ -z "$ram_pct" ]] && ram_pct=0
    ram_used=$(( ${ram_pct:-0} * ram_total / 100 ))
    load=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2, $3, $4}')
    batt_pct=$(pmset -g batt 2>/dev/null | awk -F'[%;]' '/Battery/{print $2+0}')
    batt_status=$(pmset -g batt 2>/dev/null | \
      grep -o 'charging\|discharging\|not charging\|AC Power' | head -1)
    net_ssid=$(_wifi_ssid)

    # Disk (main volume)
    local disk_pct disk_used disk_total
    read -r disk_used disk_total disk_pct <<< \
      $(df -H / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $3,$2,$5}')

    # ── Draw ────────────────────────────────────────────────
    tput cup 0 0   # move to top-left (no flicker)

    echo "${_NS_BC}╔════════════════════════════════════════════════╗${_NS_X}"
    printf "${_NS_BC}║  %-46s║${_NS_X}\n" "⚡  DEVCLI LIVE  —  $(date '+%H:%M:%S')  [Ctrl+C to exit]"
    echo "${_NS_BC}╚════════════════════════════════════════════════╝${_NS_X}"
    echo ""

    printf "  ${_NS_C}%-16s${_NS_X} " "CPU Usage"
    _ns_bar "${cpu_pct:-0}"; printf "  ${_NS_W}%s%%${_NS_X}\n" "${cpu_pct:-0}"

    printf "  ${_NS_C}%-16s${_NS_X} " "RAM Usage"
    _ns_bar "${ram_pct:-0}"; printf "  ${_NS_W}%s/%s GiB${_NS_X}\n" "$ram_used" "$ram_total"

    printf "  ${_NS_C}%-16s${_NS_X} " "Disk  (/)"
    _ns_bar "${disk_pct:-0}"; printf "  ${_NS_W}%s/%s${_NS_X}\n" "$disk_used" "$disk_total"

    echo ""
    printf "  ${_NS_C}%-16s${_NS_X} " "Load Avg"
    printf "${_NS_W}%s${_NS_X}\n" "${load:-N/A}"

    printf "  ${_NS_C}%-16s${_NS_X} " "Battery"
    if [[ -n "$batt_pct" ]]; then
      _ns_bar "${batt_pct:-0}"
      printf "  ${_NS_W}%s%%  %s${_NS_X}\n" "$batt_pct" "${batt_status:-}"
    else
      printf "${_NS_W}AC Power (no battery)${_NS_X}\n"
    fi

    echo ""
    printf "  ${_NS_C}%-16s${_NS_X} " "WiFi"
    printf "${_NS_W}%s${_NS_X}\n" "${net_ssid:-Not connected}"

    echo ""
    echo "  ${_NS_D}Refreshing every ${interval}s…${_NS_X}          "

    # Clear any stale lines below
    tput ed

    sleep "$interval"
  done
}

# ────────────────────────────────────────────────────────────
# battinfo — Battery deep-dive
# ────────────────────────────────────────────────────────────
battinfo() {
  _ns_header "🔋  BATTERY INFO"

  local raw batt_pct charging cycles health max_cap current_cap
  raw=$(system_profiler SPPowerDataType 2>/dev/null)
  batt_pct=$(pmset -g batt | awk -F'[%;]' '/Battery/{print $2+0}')
  charging=$(pmset -g batt | grep -o 'charging\|discharging\|AC Power\|not charging')
  cycles=$(echo "$raw"    | awk -F': ' '/Cycle Count/{print $2}')
  health=$(echo "$raw"    | awk -F': ' '/Condition/{print $2}')
  max_cap=$(echo "$raw"   | awk -F': ' '/Maximum Capacity/{print $2}')
  current_cap=$(echo "$raw" | awk -F': ' '/Current Capacity/{print $2}')

  printf "  ${_NS_C}%-18s${_NS_X} " "Charge"
  if [[ -n "$batt_pct" ]]; then
    _ns_bar "$batt_pct"; printf "  ${_NS_W}%s%%${_NS_X}\n" "$batt_pct"
  else
    printf "${_NS_W}AC Power (no battery)${_NS_X}\n"
  fi
  _ns_row "Status"   "${charging:-Unknown}"
  _ns_row "Health"   "${health:-Unknown}"
  _ns_row "Max Cap"  "${max_cap:-Unknown}"
  _ns_row "Cur Cap"  "${current_cap:-Unknown}"
  _ns_row "Cycles"   "${cycles:-Unknown}"
  echo ""
}

# ────────────────────────────────────────────────────────────
# netinfo — Network interfaces, IP, WiFi, DNS
# ────────────────────────────────────────────────────────────
netinfo() {
  _ns_header "🌐  NETWORK INFO"

  local pub_ip
  pub_ip=$(curl -s --max-time 4 https://api.ipify.org 2>/dev/null || echo "Offline")
  _ns_row "Public IP"  "$pub_ip"

  local iface local_ip
  for iface in $(networksetup -listallhardwareports 2>/dev/null | awk '/Device:/{print $2}'); do
    local_ip=$(ipconfig getifaddr "$iface" 2>/dev/null)
    [[ -n "$local_ip" ]] && _ns_row "[$iface]" "$local_ip"
  done

  _ns_row "WiFi SSID"  "$(_wifi_ssid)"

  local dns
  dns=$(scutil --dns 2>/dev/null | awk '/nameserver/{print $3}' | sort -u | tr '\n' '  ')
  _ns_row "DNS"        "${dns:-N/A}"

  local gw
  gw=$(netstat -rn 2>/dev/null | awk '/^default/{print $2; exit}')
  _ns_row "Gateway"    "${gw:-N/A}"

  echo ""
}

# ────────────────────────────────────────────────────────────
# speedtest — Download & upload speed via Cloudflare
# ────────────────────────────────────────────────────────────
speedtest() {
  _ns_header "🚀  SPEED TEST"
  echo "  ${_NS_D}Using Cloudflare speed endpoints…${_NS_X}"
  echo ""

  # ── Latency (ping to 1.1.1.1) ──────────────────────────
  printf "  ${_NS_C}%-18s${_NS_X} " "Ping (1.1.1.1)"
  local latency
  latency=$(ping -c 4 -q 1.1.1.1 2>/dev/null | \
    awk -F'/' '/^round-trip/{printf "%.1f ms", $5}')
  printf "${_NS_W}%s${_NS_X}\n" "${latency:-N/A}"

  # ── Download ────────────────────────────────────────────
  printf "  ${_NS_C}%-18s${_NS_X} " "Download"
  printf "${_NS_D}testing…${_NS_X}"

  local dl_bps dl_mbps
  # Download 100 MB from Cloudflare; measure bytes/sec
  dl_bps=$(curl -s -o /dev/null \
    --max-time 10 \
    -w "%{speed_download}" \
    "https://speed.cloudflare.com/__down?bytes=104857600" 2>/dev/null)
  dl_mbps=$(awk "BEGIN{printf \"%.2f\", $dl_bps / 1048576}" 2>/dev/null)

  # Overwrite "testing…" on same line
  printf "\r  ${_NS_C}%-18s${_NS_X} " "Download"
  if (( $(awk "BEGIN{print ($dl_mbps > 0)}") )); then
    local dl_col="${_NS_G}"
    (( $(awk "BEGIN{print ($dl_mbps < 5)}") )) && dl_col="${_NS_R}"
    (( $(awk "BEGIN{print ($dl_mbps < 25)}") )) && dl_col="${_NS_Y}"
    printf "${dl_col}${_NS_W}%s Mbps${_NS_X}\n" "$dl_mbps"
  else
    printf "${_NS_R}Failed${_NS_X}\n"
  fi

  # ── Upload ──────────────────────────────────────────────
  printf "  ${_NS_C}%-18s${_NS_X} " "Upload"
  printf "${_NS_D}testing…${_NS_X}"

  local ul_bps ul_mbps
  # Upload 20 MB of zeros
  ul_bps=$(dd if=/dev/zero bs=1m count=20 2>/dev/null | \
    curl -s -o /dev/null \
      --max-time 10 \
      -w "%{speed_upload}" \
      -X POST --data-binary @- \
      "https://speed.cloudflare.com/__up" 2>/dev/null)
  ul_mbps=$(awk "BEGIN{printf \"%.2f\", $ul_bps / 1048576}" 2>/dev/null)

  printf "\r  ${_NS_C}%-18s${_NS_X} " "Upload"
  if (( $(awk "BEGIN{print ($ul_mbps > 0)}") )); then
    local ul_col="${_NS_G}"
    (( $(awk "BEGIN{print ($ul_mbps < 5)}") )) && ul_col="${_NS_R}"
    (( $(awk "BEGIN{print ($ul_mbps < 10)}") )) && ul_col="${_NS_Y}"
    printf "${ul_col}${_NS_W}%s Mbps${_NS_X}\n" "$ul_mbps"
  else
    printf "${_NS_R}Failed${_NS_X}\n"
  fi

  echo ""
}

# ────────────────────────────────────────────────────────────
# diskinfo — Disk usage per volume
# ────────────────────────────────────────────────────────────
diskinfo() {
  _ns_header "💾  DISK INFO"
  df -H | awk 'NR>1 && /^\// {gsub(/%/,"",$5); print $5, $3, $2, $6}' | \
  while read -r pct used total mount; do
    [[ "$pct" =~ ^[0-9]+$ ]] || continue
    printf "  ${_NS_C}%-22s${_NS_X} " "$mount"
    _ns_bar "$pct"
    printf "  ${_NS_W}%s / %s${_NS_X}\n" "$used" "$total"
  done
  echo ""
}

# ────────────────────────────────────────────────────────────
# procinfo — Top 10 CPU & RAM hogs
# ────────────────────────────────────────────────────────────
procinfo() {
  _ns_header "📊  PROCESS INFO"
  echo "  ${_NS_BC}Top 10 by CPU:${_NS_X}"
  echo "  ${_NS_D}──────────────────────────────────────${_NS_X}"
  ps aux | sort -rk3 | head -11 | tail -10 | \
    awk '{printf "  \033[0;36m%-28s\033[0m CPU: \033[1;37m%5s%%\033[0m  MEM: \033[1;37m%5s%%\033[0m\n", $11, $3, $4}'
  echo ""
  echo "  ${_NS_BC}Top 10 by Memory:${_NS_X}"
  echo "  ${_NS_D}──────────────────────────────────────${_NS_X}"
  ps aux | sort -rk4 | head -11 | tail -10 | \
    awk '{printf "  \033[0;36m%-28s\033[0m MEM: \033[1;37m%5s%%\033[0m  CPU: \033[1;37m%5s%%\033[0m\n", $11, $4, $3}'
  echo ""
}

# ────────────────────────────────────────────────────────────
# portscan — Open listening ports
# ────────────────────────────────────────────────────────────
portscan() {
  _ns_header "🔌  OPEN PORTS"
  echo "  ${_NS_D}Proto   Port     Process${_NS_X}"
  echo "  ${_NS_D}──────────────────────────────────────${_NS_X}"
  sudo lsof -iTCP -iUDP -sTCP:LISTEN -P -n 2>/dev/null | \
    awk 'NR>1 {printf "  \033[0;36m%-8s\033[0m \033[1;37m%-10s\033[0m %s\n", $8, $9, $1}' | sort -u
  echo ""
}

# ────────────────────────────────────────────────────────────
# tempinfo — CPU thermals
# ────────────────────────────────────────────────────────────
tempinfo() {
  _ns_header "🌡️   THERMAL INFO"
  if command -v osx-cpu-temp &>/dev/null; then
    _ns_row "CPU Temp" "$(osx-cpu-temp)"
  else
    _ns_row "Note" "brew install osx-cpu-temp  for sensor data"
  fi
  echo ""
}

# ────────────────────────────────────────────────────────────
# _devcli_version_gt  — compare semver strings
# ────────────────────────────────────────────────────────────
_devcli_version_gt() {
  # Returns 0 (true) if $1 > $2 as semver
  [[ "$1" == "$2" ]] && return 1
  local IFS=.
  local -a a=( ${=1} ) b=( ${=2} )
  for (( i=0; i<3; i++ )); do
    local ai=${a[i+1]:-0} bi=${b[i+1]:-0}
    (( ai > bi )) && return 0
    (( ai < bi )) && return 1
  done
  return 1
}

# ────────────────────────────────────────────────────────────
# _devcli_check_update — silent background check (once/day)
# ────────────────────────────────────────────────────────────
_devcli_check_update() {
  {
    # Only check once per day using a cache file
    local cache="$DEVCLI_UPDATE_CACHE"
    local now=$(date +%s)
    if [[ -f "$cache" ]]; then
      local last_check=$(cat "$cache" 2>/dev/null | head -1)
      local age=$(( now - ${last_check:-0} ))
      (( age < 86400 )) && return 0   # checked within 24h, skip
    fi

    # Fetch latest release tag from GitHub API
    local latest
    latest=$(curl -sf --max-time 5 \
      "https://api.github.com/repos/${DEVCLI_REPO}/releases/latest" \
      2>/dev/null | grep '"tag_name"' | sed 's/.*"v\?\([^"]*\)".*/\1/')

    [[ -z "$latest" ]] && return 0   # offline or API unreachable

    # Save timestamp + latest version
    mkdir -p "$(dirname "$cache")"
    printf '%s\n%s\n' "$now" "$latest" > "$cache"

    # Notify user if a newer version exists
    if _devcli_version_gt "$latest" "$DEVCLI_VERSION"; then
      print -P ""
      print -P "%F{cyan}  DevCLI v${latest} is available!%f  (you have v${DEVCLI_VERSION})"
      print -P "%F{245}  Run %F{cyan}devcli update%F{245} to upgrade.%f"
      print -P ""
    fi
  } &!   # run silently in background, don't block shell startup
}

# ────────────────────────────────────────────────────────────
# devcli update — upgrade to the latest release
# ────────────────────────────────────────────────────────────
devcliupdate() {
  _ns_header "🔄  DEVCLI UPDATE"

  # Check what version is latest
  printf "  ${_NS_C}%-18s${_NS_X} ${_NS_D}checking…${_NS_X}\n" "Current"
  printf "\r  ${_NS_C}%-18s${_NS_X} ${_NS_W}%s${_NS_X}\n" "Current" "v${DEVCLI_VERSION}"

  local latest
  latest=$(curl -sf --max-time 8 \
    "https://api.github.com/repos/${DEVCLI_REPO}/releases/latest" \
    2>/dev/null | grep '"tag_name"' | sed 's/.*"v\?\([^"]*\)".*/\1/')

  if [[ -z "$latest" ]]; then
    printf "  ${_NS_R}Could not reach GitHub. Check your connection.${_NS_X}\n\n"
    return 1
  fi

  printf "  ${_NS_C}%-18s${_NS_X} ${_NS_W}%s${_NS_X}\n" "Latest" "v${latest}"
  echo ""

  if ! _devcli_version_gt "$latest" "$DEVCLI_VERSION"; then
    printf "  ${_NS_G}✔ Already up to date!${_NS_X}\n\n"
    return 0
  fi

  printf "  ${_NS_Y}Upgrading v${DEVCLI_VERSION} → v${latest}…${_NS_X}\n\n"

  # ── Upgrade path: Homebrew (preferred) ───────────────────
  if command -v brew &>/dev/null && brew list devcli &>/dev/null 2>&1; then
    printf "  ${_NS_C}Using Homebrew…${_NS_X}\n"
    brew upgrade devcli && \
      printf "  ${_NS_G}✔ Upgraded via Homebrew!${_NS_X}\n\n" && \
      return 0
  fi

  # ── Upgrade path: direct from GitHub tarball ─────────────
  local tmpdir
  tmpdir=$(mktemp -d)
  local tarball_url="https://github.com/${DEVCLI_REPO}/archive/refs/tags/v${latest}.tar.gz"

  printf "  ${_NS_C}Downloading v${latest}…${_NS_X}\n"
  if ! curl -sL --max-time 30 "$tarball_url" | tar -xz -C "$tmpdir" 2>/dev/null; then
    printf "  ${_NS_R}✘ Download failed.${_NS_X}\n\n"
    rm -rf "$tmpdir"
    return 1
  fi

  local extracted
  extracted=$(ls "$tmpdir" | head -1)
  local install_script="$tmpdir/$extracted/install.sh"

  if [[ ! -f "$install_script" ]]; then
    printf "  ${_NS_R}✘ install.sh not found in release.${_NS_X}\n\n"
    rm -rf "$tmpdir"
    return 1
  fi

  chmod +x "$install_script"
  zsh "$install_script"

  rm -rf "$tmpdir"

  # Bust the update cache so next shell shows no alert
  rm -f "$DEVCLI_UPDATE_CACHE" 2>/dev/null

  printf "  ${_NS_G}✔ DevCLI updated to v${latest}!${_NS_X}\n"
  printf "  ${_NS_D}Restart your terminal to apply changes.${_NS_X}\n\n"
}

# ────────────────────────────────────────────────────────────
# devcli — Help
# ────────────────────────────────────────────────────────────
devcli() {
  echo ""
  echo "${_NS_BC}  DevCLI Commands${_NS_X}  ${_NS_D}(v${DEVCLI_VERSION})${_NS_X}"
  echo "${_NS_D}  ──────────────────────────────────────${_NS_X}"
  echo "  ${_NS_C}sysinfo${_NS_X}       Snapshot: OS, CPU, RAM, GPU"
  echo "  ${_NS_C}syswatch${_NS_X}      Live dashboard (refreshes every 2s)"
  echo "  ${_NS_C}battinfo${_NS_X}      Battery status & health"
  echo "  ${_NS_C}netinfo${_NS_X}       Network interfaces, WiFi & DNS"
  echo "  ${_NS_C}speedtest${_NS_X}     Download / upload / ping test"
  echo "  ${_NS_C}diskinfo${_NS_X}      Disk usage per volume"
  echo "  ${_NS_C}procinfo${_NS_X}      Top processes by CPU & RAM"
  echo "  ${_NS_C}portscan${_NS_X}      Open listening ports"
  echo "  ${_NS_C}tempinfo${_NS_X}      CPU temperature"
  echo "  ${_NS_C}devcliupdate${_NS_X}  Check & install latest version"
  echo "  ${_NS_C}devcli${_NS_X}        Show this help"
  echo ""
  echo "  ${_NS_D}Tip: syswatch [seconds]  e.g. syswatch 1${_NS_X}"
  echo ""
}

# ── Run update check in background on every new shell ────────
_devcli_check_update
