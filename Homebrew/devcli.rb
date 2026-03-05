# typed: false
# frozen_string_literal: true

class Devcli < Formula
  desc "Linux-style developer terminal theme for macOS Terminal.app"
  homepage "https://github.com/Ruhanpaco/DevCLI"
  url "https://github.com/Ruhanpaco/DevCLI/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "777dd974e3d36fad00568e4b235b66eff50082b9924355ab7243f0b8cd54c599"
  license "MIT"
  version "1.0.0"

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
