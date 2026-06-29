#!/usr/bin/env bash
# Juice installer (curl|bash fallback — `brew install --cask juice` is preferred).
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/tcashel/homebrew-juice/main/install.sh | bash
# Flags: --force  --no-verify  --version vX.Y.Z
#
# This script lives in the PUBLIC tap repo because the Juice source repo is
# private — its release assets aren't anonymously downloadable. The notarized
# Juice.zip is hosted on this repo's GitHub Releases. See tcashel/juice ADR 0015.
set -euo pipefail

REPO="tcashel/homebrew-juice"
APP_NAME="Juice.app"
ASSET="Juice.zip"
SHA="Juice.zip.sha256"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"

FORCE=0
VERIFY=1
VERSION=""

err()  { printf 'error: %s\n' "$*" >&2; }
info() { printf '%s\n' "$*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)     FORCE=1; shift ;;
    --no-verify) VERIFY=0; shift ;;
    --version)   VERSION="${2:-}"; shift 2 ;;
    -h|--help)   sed -n '2,5p' "$0"; exit 0 ;;
    *) err "unknown arg: $1"; exit 2 ;;
  esac
done

read -r OS ARCH < <(uname -sm)
if [[ "$OS" != "Darwin" || "$ARCH" != "arm64" ]]; then
  err "Juice requires macOS on Apple Silicon (got $OS $ARCH)"
  exit 1
fi

for tool in curl ditto xattr shasum grep sed; do
  command -v "$tool" >/dev/null || { err "missing required tool: $tool"; exit 1; }
done

TMP="$(mktemp -d -t juice-install.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

if [[ -n "$VERSION" ]]; then
  API="https://api.github.com/repos/$REPO/releases/tags/$VERSION"
else
  API="https://api.github.com/repos/$REPO/releases/latest"
fi

info "Resolving release..."
curl -fsSL -H 'Accept: application/vnd.github+json' "$API" -o "$TMP/release.json" \
  || { err "failed to fetch $API"; exit 1; }

# Extract a browser_download_url ending in the given filename.
# GitHub's JSON shape is stable; --no-verify is the escape hatch if it ever changes.
extract_url() {
  grep -Eo "\"browser_download_url\":[[:space:]]*\"[^\"]*$1\"" "$TMP/release.json" \
    | head -1 \
    | sed -E 's/.*"(https[^"]+)".*/\1/'
}

ASSET_URL="$(extract_url "$ASSET")"
[[ -n "$ASSET_URL" ]] || { err "release missing asset: $ASSET"; exit 1; }

info "Downloading $ASSET ..."
curl -fsSL --retry 3 -o "$TMP/$ASSET" "$ASSET_URL"

if [[ "$VERIFY" -eq 1 ]]; then
  SHA_URL="$(extract_url "$SHA")"
  if [[ -z "$SHA_URL" ]]; then
    err "checksum missing in release; re-run with --no-verify to skip"
    exit 1
  fi
  info "Verifying SHA256 ..."
  curl -fsSL -o "$TMP/$SHA" "$SHA_URL"
  ( cd "$TMP" && shasum -a 256 -c "$SHA" ) || { err "checksum mismatch"; exit 1; }
fi

info "Extracting ..."
ditto -x -k "$TMP/$ASSET" "$TMP/extracted"
SRC="$TMP/extracted/$APP_NAME"
[[ -d "$SRC" ]] || { err "expected $APP_NAME inside archive"; exit 1; }

DEST="$INSTALL_DIR/$APP_NAME"

maybe_sudo() {
  if [[ -w "$INSTALL_DIR" ]]; then
    "$@"
  elif [[ -t 0 && -t 1 ]]; then
    info "$INSTALL_DIR not writable; using sudo for: $1"
    sudo "$@"
  else
    err "$INSTALL_DIR not writable and no TTY for sudo."
    err "Re-run with: sudo bash install.sh   (or set INSTALL_DIR=\$HOME/Applications)"
    exit 1
  fi
}

if [[ -e "$DEST" ]]; then
  if [[ "$FORCE" -ne 1 && -t 0 && -t 1 ]]; then
    read -r -p "$DEST exists. Overwrite? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { info "aborted."; exit 0; }
  fi
  maybe_sudo rm -rf "$DEST"
fi

maybe_sudo ditto "$SRC" "$DEST"

# Report Gatekeeper's verdict before clearing quarantine. A notarized build passes
# ("accepted … Notarized Developer ID"); the interim ad-hoc build won't — that's
# expected while the Developer ID cert is being wired. The sha256 check above already
# covered download integrity.
if command -v spctl >/dev/null 2>&1; then
  spctl --assess --type execute --verbose=2 "$DEST" 2>&1 | sed 's/^/  gatekeeper: /' || true
fi

# Notarized builds open without this; for the interim ad-hoc build it's required, and
# it's harmless on a notarized build (no quarantine xattr to remove).
maybe_sudo xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

# Symlink juice-mcpbridge into /usr/local/bin so MCP clients can spawn it
# without knowing the app bundle path. (The Homebrew cask instead symlinks it
# into $(brew --prefix)/bin via its `binary` stanza.) The bridge is the stdio
# shim from ADR 0007; agents reach the running Juice.app via Mach-named XPC.
# `ln -sfn` is idempotent — re-installs replace the symlink without prompting.
BRIDGE_BIN="$DEST/Contents/MacOS/juice-mcpbridge"
SYMLINK="/usr/local/bin/juice-mcpbridge"
if [[ -x "$BRIDGE_BIN" ]]; then
  if [[ ! -d "/usr/local/bin" ]]; then
    maybe_sudo mkdir -p /usr/local/bin
  fi
  if maybe_sudo ln -sfn "$BRIDGE_BIN" "$SYMLINK" 2>/dev/null; then
    info "Symlinked: $SYMLINK"
    info "MCP setup: claude mcp add juice -- juice-mcpbridge"
    # Apple Silicon Macs often ship with /usr/local/bin off the default PATH
    # (Homebrew lives at /opt/homebrew/bin). Surface the gap so the user
    # doesn't run `claude mcp add` and hit a "command not found" later.
    case ":${PATH}:" in
      *":/usr/local/bin:"*)
        ;;  # already on PATH
      *)
        info "Note: /usr/local/bin is not on your PATH."
        info "      Add it to your shell config or symlink to a PATH dir, e.g.:"
        info "      ln -sfn '$BRIDGE_BIN' /opt/homebrew/bin/juice-mcpbridge"
        ;;
    esac
  else
    info "Note: could not create $SYMLINK (sudo declined or read-only fs)."
    info "      Run manually for CLI access: ln -sfn '$BRIDGE_BIN' '$SYMLINK'"
  fi
else
  info "Note: juice-mcpbridge not present in this build."
fi

info ""
info "Installed: $DEST"
info "Launch:    open '$DEST'"
