#!/usr/bin/env bash
# Canonical non-Homebrew installer for the notarized public Juice release.

set -euo pipefail

repo="tcashel/homebrew-juice"
asset="Juice.zip"
destination="/Applications/Juice.app"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/juice-install.XXXXXX")"
stage="/Applications/.Juice.install.$$"
backup="/Applications/.Juice.backup.$$"
admin=()

cleanup() {
  rm -rf "$temporary_root"
  if [[ -e "$backup" && ! -e "$destination" ]]; then
    "${admin[@]}" mv "$backup" "$destination" || true
  fi
  if [[ -e "$stage" ]]; then
    "${admin[@]}" rm -rf "$stage" || true
  fi
}
trap cleanup EXIT

fail() {
  echo "juice installer: $*" >&2
  exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || fail "Juice requires macOS"
[[ "$(uname -m)" == "arm64" ]] || fail "Juice requires Apple Silicon"

base_url="https://github.com/${repo}/releases/latest/download"
curl_flags=(--fail --silent --show-error --location --proto '=https' --tlsv1.2)
curl "${curl_flags[@]}" "${base_url}/${asset}" -o "${temporary_root}/${asset}"
curl "${curl_flags[@]}" "${base_url}/${asset}.sha256" -o "${temporary_root}/${asset}.sha256"

expected_sha="$(awk 'NR == 1 { print $1 }' "${temporary_root}/${asset}.sha256")"
[[ "$expected_sha" =~ ^[0-9a-f]{64}$ ]] || fail "release checksum is malformed"
actual_sha="$(shasum -a 256 "${temporary_root}/${asset}" | awk '{ print $1 }')"
[[ "$actual_sha" == "$expected_sha" ]] || fail "release checksum does not match"

ditto -x -k "${temporary_root}/${asset}" "$temporary_root/unpacked"
source_app="${temporary_root}/unpacked/Juice.app"
[[ -d "$source_app" ]] || fail "release archive does not contain Juice.app"

# These gates are mandatory. Never clear quarantine or continue after a failed
# Gatekeeper assessment: the fallback exists only for Developer ID signed,
# notarized, and stapled public artifacts.
codesign --verify --deep --strict --verbose=2 "$source_app"
xcrun stapler validate "$source_app"
spctl --assess --type execute --verbose=2 "$source_app"

if [[ ! -w /Applications ]]; then
  admin=(sudo)
fi

"${admin[@]}" rm -rf "$stage" "$backup"
"${admin[@]}" ditto "$source_app" "$stage"
if [[ -e "$destination" ]]; then
  "${admin[@]}" mv "$destination" "$backup"
fi
if "${admin[@]}" mv "$stage" "$destination"; then
  "${admin[@]}" rm -rf "$backup"
else
  if [[ -e "$backup" ]]; then
    "${admin[@]}" mv "$backup" "$destination"
  fi
  fail "could not install Juice.app"
fi

codesign --verify --deep --strict --verbose=2 "$destination"
xcrun stapler validate "$destination"
spctl --assess --type execute --verbose=2 "$destination"
echo "Installed verified Juice.app at $destination"
