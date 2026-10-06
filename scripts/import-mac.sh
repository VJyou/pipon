#!/usr/bin/env bash
# Run on the Mac mini: import what scripts/export-linux.sh put on the USB stick.
#   scripts/import-mac.sh /Volumes/<USB>/zkcred-export
# Never overwrites an existing keypair or file; never prints key contents.
set -euo pipefail
SRC=${1:?usage: $0 <export directory on the USB stick>}
REPO="$(cd "$(dirname "$0")/.." && pwd)"

echo "== checksums"
(cd "$SRC" && shasum -a 256 -c --quiet SHA256SUMS) && echo "  all OK"

echo "== Solana keypairs"
mkdir -p "$HOME/.config/solana"
chmod 700 "$HOME/.config/solana"
for f in "$SRC"/solana/*.json; do
  [ -e "$f" ] || continue
  dst="$HOME/.config/solana/$(basename "$f")"
  if [ -e "$dst" ]; then echo "  exists, skipped: $(basename "$f")"; continue; fi
  cp "$f" "$dst" && chmod 600 "$dst"
  pub=$(solana-keygen pubkey "$dst" 2>/dev/null || echo "?")
  echo "  $(basename "$f") -> $pub"
done

echo "== program keypair"
mkdir -p "$REPO/target/deploy"
for f in "$SRC"/program/*-keypair.json; do
  [ -e "$f" ] || continue
  dst="$REPO/target/deploy/$(basename "$f")"
  if [ -e "$dst" ]; then echo "  exists, skipped: $(basename "$f") (anchor may have generated a new one: compare with Anchor.toml)"; continue; fi
  cp "$f" "$dst" && chmod 600 "$dst"
  echo "  $(basename "$f") -> $(solana-keygen pubkey "$dst" 2>/dev/null || echo "?") (Anchor.toml: AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK)"
done

echo "== ptau"
mkdir -p "$HOME/ptau"
for f in "$SRC"/ptau/*.ptau; do
  [ -e "$f" ] || continue
  cp -n "$f" "$HOME/ptau/" && echo "  $(basename "$f")"
done

echo "== circuits/build (existing files are kept)"
mkdir -p "$REPO/circuits/build"
cp -Rn "$SRC/circuits-build/." "$REPO/circuits/build/" || true  # macOS cp -n exits 1 when it skips a file
# The zkey must be the one behind the deployed verifying key.
a=$(shasum -a 256 "$SRC/circuits-build/jpki_age_region.zkey" | cut -d' ' -f1)
b=$(shasum -a 256 "$REPO/circuits/build/jpki_age_region.zkey" | cut -d' ' -f1)
[ "$a" = "$b" ] && echo "  zkey matches the Mac copy" || echo "  WARNING: zkey differs from the Mac copy"

echo "done. Upgrade authority in docs/deployments.md: 7LQSbKRwxW7argJ4mUcLyRsPvq8yuzfzvxVr8aightAR"
echo "Delete the keypairs from the USB stick now: rm $SRC/solana/*.json $SRC/program/*.json"
