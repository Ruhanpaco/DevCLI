<div align="center">

```
  ____  _         ____ _     ___
 |  _ \| |__ __ _/ ___| |   |_ _|
 | | | | / _ \ \ / /   | |    | |
 | |_| |  __/\ V / /___| |___ | |
 |____/ \___| \_/ \____|_____|___|
```

**Linux-style developer terminal theme for macOS**

![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white)
![Zsh](https://img.shields.io/badge/Zsh-5.x+-1A1A1A?style=flat&logo=gnu-bash&logoColor=white)
![Homebrew](https://img.shields.io/badge/Homebrew-ready-FBB040?style=flat&logo=homebrew&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat)

</div>

---

## What is DevCLI?

DevCLI transforms your default macOS Terminal into a powerful, Linux-inspired environment — no third-party apps required. It ships with **4 colour themes**, a **two-line Zsh prompt** with git integration, an **Apple-logo system info panel**, and a set of **custom commands** that give you instant deep dives into your machine.

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🎨 **4 Themes** | Dark, Glass (transparent), Abyss (pure black), Ghost (light) |
| 🔁 **Linux-style Prompt** | `┌──(user㉿host)-[~/path]` with git branch & exit-code colour |
| 🍎 **System Info** | `fastfetch` with Apple logo on every new session |
| 🛠️ **Dev Commands** | `sysinfo`, `battinfo`, `netinfo`, `diskinfo`, `procinfo`, and more |
| 📦 **Homebrew Ready** | One-command install once published |
| ⚡ **Zero Dependencies** | Works with the built-in macOS Terminal.app |

---

## 🚀 Installation

### Option A — Local (immediate)

```sh
git clone https://github.com/YOUR_USERNAME/devcli.git
cd devcli
./install.sh
```

Open a **new terminal window** — everything is active.

### Option B — Homebrew (after publishing)

```sh
brew tap YOUR_USERNAME/devcli
brew install devcli
devcli install
```

---

## 🎨 Themes

Switch between themes at any time:

> **Terminal → Settings → Profiles → select a DevCLI theme → click Default**

| Theme | Background | Best For |
|-------|-----------|----------|
| **DevCLI Dark** | Deep navy `#0d1117` | All-day coding |
| **DevCLI Glass** | 75% transparent + blur | Wallpaper-forward setups |
| **DevCLI Abyss** | Pure `#000000` | Maximum contrast |
| **DevCLI Ghost** | Off-white `#fafafc` | Light-mode environments |

---

## 🛠️ Custom Commands

Run `devcli` to list everything. A few highlights:

```sh
sysinfo      # OS, CPU, GPU, RAM — styled overview
battinfo     # Battery charge, health, cycle count
netinfo      # Public IP, WiFi SSID, DNS, gateway
diskinfo     # Per-volume usage bars
procinfo     # Top 10 processes by CPU & RAM
portscan     # Open listening ports
tempinfo     # CPU temperature & fan speed
```

---

## 📁 File Structure

```
devcli/
├── src/
│   ├── DevCLI-Dark.terminal      # Terminal.app colour profile (dark)
│   ├── DevCLI-Glass.terminal     # Transparent profile
│   ├── DevCLI-Abyss.terminal     # Pure black profile
│   ├── DevCLI-Ghost.terminal     # Light mode profile
│   ├── devcli.zsh-theme          # Zsh prompt theme
│   ├── devcli_commands.zsh       # Custom info commands
│   └── fastfetch.jsonc           # System info config (Apple logo)
├── Homebrew/
│   └── devcli.rb                 # Homebrew formula
├── generate_terminal_profile.py  # Regenerate .terminal files
├── install.sh                    # One-click local installer
└── README.md
```

---

## 🔄 Uninstall

1. **Terminal.app colours** — `Terminal → Settings → Profiles` → delete DevCLI profiles
2. **Zsh prompt** — remove the `source ~/.config/zsh/devcli.zsh-theme` line from `~/.zshrc`
3. **Commands** — remove the `source ~/.config/zsh/devcli_commands.zsh` line from `~/.zshrc`
4. **Fastfetch** — delete `~/.config/fastfetch/config.jsonc`

---

## Publishing to Homebrew

1. Push this repo to GitHub as `homebrew-devcli`
2. Create a release tag `v1.0.0` and note the `.tar.gz` URL
3. Run `shasum -a 256 v1.0.0.tar.gz` to get the hash
4. Fill in `url` and `sha256` in `Homebrew/devcli.rb`
5. Replace `YOUR_USERNAME` everywhere and push

---

## License

MIT © YOUR_USERNAME
