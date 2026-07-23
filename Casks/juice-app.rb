# typed: strict
# frozen_string_literal: true

# Canonical Homebrew cask template for Juice (ADR 0015).
#
# This file is the source of truth. On each tagged release, CI renders it
# (substituting 0.3.0 and 33cd3fc84cb7a913eecc7c0cc369988771e81fa05b956a7ab0f932561e04599c from the built, notarized artifact)
# and commits the result to the PUBLIC tap repo `tcashel/homebrew-juice` as
# `Casks/juice-app.rb`. The binary itself is hosted on that public repo's
# GitHub Releases, so anonymous users can `brew install --cask juice-app` even
# though the source repo `tcashel/juice` is private.
#
# Token is `juice-app`, not `juice`: the bare `juice` cask is already taken in
# the official Homebrew/homebrew-cask (a battery widget), so `brew install
# --cask juice` would resolve to that, not us.
#
# Local render + validate:
#   V=1.0.0 S=$(shasum -a 256 dist/Juice.zip | awk '{print $1}')
#   sed "s|0.3.0|$V|g; s|33cd3fc84cb7a913eecc7c0cc369988771e81fa05b956a7ab0f932561e04599c|$S|g" packaging/homebrew/juice.rb > /tmp/juice-app.rb
#   brew style /tmp/juice-app.rb && brew audit --cask /tmp/juice-app.rb
cask "juice-app" do
  version "0.3.0"
  sha256 "33cd3fc84cb7a913eecc7c0cc369988771e81fa05b956a7ab0f932561e04599c"

  url "https://github.com/tcashel/homebrew-juice/releases/download/v#{version}/Juice.zip"
  name "Juice"
  desc "Mines AI coding-agent session histories into per-repo optimizations"
  homepage "https://github.com/tcashel/juice"

  # arm64-only build; the deployment target is 26.3 — :tahoe gates at the
  # macOS 26 major version (Homebrew can't express a minor-version floor).
  depends_on arch: :arm64
  depends_on macos: :tahoe

  # Both public commands are signed inside the app artifact. The CLI lives in
  # Contents/Helpers because `Juice` and `juice` collide on case-insensitive
  # macOS volumes when placed together in Contents/MacOS.
  app "Juice.app"
  binary "#{appdir}/Juice.app/Contents/MacOS/juice-mcpbridge"
  binary "#{appdir}/Juice.app/Contents/Helpers/juice"
  manpage "#{appdir}/Juice.app/Contents/Resources/juice.1"
  bash_completion "#{appdir}/Juice.app/Contents/Resources/juice.bash"
  fish_completion "#{appdir}/Juice.app/Contents/Resources/juice.fish"
  zsh_completion "#{appdir}/Juice.app/Contents/Resources/_juice"

  uninstall launchctl: "com.juice.app.JuiceService",
            quit:      "com.juice.Juice"

  zap trash: [
    "~/Library/Application Support/Juice",
    "~/Library/Caches/com.juice.Juice",
    "~/Library/Preferences/com.juice.Juice.plist",
    "~/Library/Saved Application State/com.juice.Juice.savedState",
  ]

  caveats <<~EOS
    Enable CLI access in Juice → Settings → Advanced → Agent API, then run:
      juice status

    Register the bundled MCP bridge so clients like Claude Code can reach Juice:
      claude mcp add juice -- juice-mcpbridge
  EOS
end
