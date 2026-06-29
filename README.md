# homebrew-juice

Homebrew tap for **[Juice](https://github.com/tcashel/juice)** — a native macOS app that
mines your AI coding-agent session histories (Claude Code, Codex, …) into per-repo
optimizations.

The Juice source repo is private; this public tap hosts the app binary and the cask so
anyone can install it.

## Install

```sh
brew tap tcashel/juice
brew install --cask juice-app
```

The cask token is `juice-app`, not `juice` — the bare `juice` cask name is already taken
in the official Homebrew cask repo.

The Developer ID build is notarized and stapled, so it opens normally — no Gatekeeper
prompt, no `xattr` dance. **While the project is still on its interim ad-hoc-signed
build,** Gatekeeper will quarantine it, so clear the quarantine once after installing
(current Homebrew dropped the old `--no-quarantine` flag):

```sh
brew install --cask juice-app
xattr -dr com.apple.quarantine /Applications/Juice.app
```

Requirements: macOS 26 (Tahoe) or newer, Apple Silicon (M-series), and
[Claude Code](https://claude.ai/code) (`claude` on your PATH).

### Connect it to your MCP client

The cask symlinks the `juice-mcpbridge` stdio shim onto your PATH. Register it once:

```sh
claude mcp add juice -- juice-mcpbridge
```

### curl | bash fallback (no Homebrew)

```sh
curl -fsSL https://raw.githubusercontent.com/tcashel/homebrew-juice/main/install.sh | bash
```

Downloads the latest `Juice.zip`, verifies its SHA-256, installs to `/Applications`, and
symlinks `juice-mcpbridge` into `/usr/local/bin`. Read [`install.sh`](./install.sh) before
piping it to a shell.

## Updating / uninstalling

```sh
brew upgrade --cask juice-app
brew uninstall --cask juice-app          # add --zap to also remove app data
```

## How releases land here

Tagging `v*` in the private `tcashel/juice` repo runs CI that builds, signs (Developer ID
+ notarize + staple once the cert is wired; ad-hoc in the interim), then cross-uploads
`Juice.zip` to this repo's Releases and re-renders [`Casks/juice-app.rb`](./Casks). See
ADR 0015 in the source repo.
