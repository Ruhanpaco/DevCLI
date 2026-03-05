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
    libexec.install "src", "install.sh", "patch_zshrc.zsh", "import_profiles.py", "generate_terminal_profile.py"

    (bin/"devcli").write <<~SH
      #!/usr/bin/env zsh
      exec "#{libexec}/install.sh" "$@"
    SH
    chmod 0755, bin/"devcli"
  end

  def caveats
    <<~EOS
      DevCLI has been installed! Run:
        devcli install

      This will:
        • Import 4 colour profiles into Terminal.app (Dark, Glass, Abyss, Ghost)
        • Configure your Zsh prompt (Linux two-line style with git branch)
        • Set up fastfetch with Apple logo on each session start
        • Add custom commands: sysinfo, syswatch (live), speedtest, battinfo,
          netinfo, diskinfo, procinfo, portscan, tempinfo

      Switch themes:
        Shell menu → Use Profile → pick a DevCLI theme  (current window)
        Terminal → Settings → Profiles → Default         (new windows)

      Show all commands:
        devcli
    EOS
  end

  test do
    assert_predicate bin/"devcli", :exist?
    assert_predicate bin/"devcli", :executable?
  end
end
