# typed: false
# frozen_string_literal: true

class Devcli < Formula
  desc "Linux-style developer terminal theme for macOS Terminal.app"
  homepage "https://github.com/Ruhanpaco/DevCLI"
  url "https://github.com/Ruhanpaco/DevCLI/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "92d138a15310e0f806931ad48533d11d029ffe32ee94d8606f80554eab2004ef"
  license "MIT"
  version "1.0.1"

  depends_on "fastfetch"

  def install
    # Ship all source files and the installer into the brew prefix
    libexec.install "src", "install.sh", "patch_zshrc.zsh", "generate_terminal_profile.py"

    # Thin wrapper so `devcli install` works from PATH
    (bin/"devcli").write <<~SH
      #!/usr/bin/env zsh
      exec "#{libexec}/install.sh" "$@"
    SH
    chmod 0755, bin/"devcli"
  end

  def caveats
    <<~EOS
      DevCLI has been installed!

      Apply the theme by running:
        devcli install

      What the installer does:
        • Imports 4 colour profiles into Terminal.app (Dark, Glass, Abyss, Ghost)
        • Sets up your Zsh prompt (Linux two-line style)
        • Configures fastfetch with Apple logo on session start
        • Adds custom commands: sysinfo, syswatch, battinfo, netinfo,
          speedtest, diskinfo, procinfo, portscan, tempinfo

      Switch themes:
        Terminal → Settings → Profiles → pick a DevCLI theme → Default

      Show all commands:
        devcli

    EOS
  end

  test do
    assert_predicate bin/"devcli", :exist?
    assert_predicate bin/"devcli", :executable?
    assert_match "install.sh", shell_output("ls #{libexec}")
  end
end
