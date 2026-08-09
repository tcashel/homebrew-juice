# Juice

Juice is a native macOS app that turns local Claude Code and Codex histories into bounded, cited context and repository provenance.

## Install

Requirements: Apple Silicon and macOS 26.3 or newer.

```sh
brew tap tcashel/juice
brew trust --cask tcashel/juice/juice-app
brew install --cask juice-app
```

The app is Developer ID signed, notarized, and stapled. Open Juice after installation and use **Settings → Connections** to connect detected Claude Code and Codex clients. To use the `juice` command directly, enable **Settings → Advanced → Agent API → Juice CLI access**.

The cask token is `juice-app`. The bare `juice` token belongs to a different app in Homebrew's official cask repository.

## Agent workflow plugin

The optional skills-only plugin teaches an agent when to query Juice. It does not bundle another MCP server or credential; Juice's in-app Connect flow remains the revocable local data boundary.

Claude Code:

```text
/plugin marketplace add tcashel/homebrew-juice
/plugin install juice@juice
```

Codex CLI:

```sh
codex plugin marketplace add tcashel/homebrew-juice
codex plugin add juice@juice
```

## Update or uninstall

```sh
brew upgrade --cask juice-app
brew uninstall --cask juice-app
```

Without Homebrew, inspect and run the public installer:

```sh
curl -fsSL https://raw.githubusercontent.com/tcashel/homebrew-juice/main/install.sh | bash
```

The canonical installer verifies the release checksum, Developer ID signature,
stapled notarization ticket, and Gatekeeper assessment. It never clears
quarantine or continues after a failed assessment.
