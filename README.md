# homebrew-juice

Homebrew tap for **[Juice](https://github.com/tcashel/juice)** — a native macOS app that
mines your AI coding-agent session histories (Claude Code, Codex, …) into per-repo
optimizations.

The Juice source repo is private; this public tap hosts the notarized app binary and the
cask so anyone can install it.

## Install

```sh
brew tap tcashel/juice
brew install --cask juice
```

The app is signed with a Developer ID certificate and notarized by Apple, so it opens
normally — no Gatekeeper prompt, no `xattr` dance.

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

Downloads the latest notarized `Juice.zip`, verifies its SHA-256, installs to
`/Applications`, and symlinks `juice-mcpbridge` into `/usr/local/bin`. Read
[`install.sh`](./install.sh) before piping it to a shell.

## Updating / uninstalling

```sh
brew upgrade --cask juice
brew uninstall --cask juice          # add --zap to also remove app data
```

## How releases land here

Tagging `v*` in the private `tcashel/juice` repo runs CI that builds, signs, notarizes, and
staples `Juice.app`, then cross-uploads `Juice.zip` to this repo's Releases and re-renders
[`Casks/juice.rb`](./Casks/juice.rb). See ADR 0015 in the source repo.
