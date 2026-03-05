# typed: false
# frozen_string_literal: true

class Devcli < Formula
  desc "Linux-style developer terminal theme for macOS Terminal.app"
  homepage "https://github.com/YOUR_USERNAME/devcli"
  url "https://github.com/YOUR_USERNAME/devcli/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256_OF_YOUR_TARBALL"
  license "MIT"
  version "1.0.0"

  depends_on "fastfetch"

  def install
    libexec.install "src", "install.sh"
    (bin/"devcli").write <<~SH
      #!/usr/bin/env zsh
      exec "#{libexec}/install.sh" "$@"
    SH
    chmod 0755, bin/"devcli"
  end

  def caveats
    <<~EOS
      DevCLI has been installed!

      To apply the theme, run:
        devcli install

      This will:
        • Install 4 colour profiles to Terminal.app (Dark, Glass, Abyss, Ghost)
        • Configure your Zsh prompt (two-line Linux-style)
        • Set up fastfetch for system info on launch
        • Add custom commands: sysinfo, battinfo, netinfo, diskinfo, procinfo...

      Open a new Terminal window after running the installer.
      Switch themes: Terminal → Settings → Profiles → pick a DevCLI theme → Default
    EOS
  end

  test do
    assert_predicate bin/"devcli", :exist?
    assert_predicate bin/"devcli", :executable?
  end
end
