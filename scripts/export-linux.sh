#!/usr/bin/env bash
# Run on the Linux box: copy everything the Mac mini needs onto a USB stick (exFAT; FAT32 cannot hold files > 4 GB).
#   scripts/export-linux.sh /media/$USER/<USB>/zkcred-export
# Copies: Solana keypairs (~/.config/solana/*.json), program keypairs (target/deploy), ptau files (~/ptau), all of circuits/build/.
# Never prints key contents. Keypairs are secrets: delete them from the USB stick after the import.
set -euo pipefail
DEST=${1:?usage: $0 <destination directory on the USB stick>}
REPO="$(cd "$(dirname "$0")/.." && pwd)"

echo "== repository"
cd "$REPO"
git fetch -q origin main || true
if [ -n "$(git status --porcelain)" ]; then
  echo "WARNING: uncommitted changes on the Linux box (commit + push them, or they stay behind):"
  git status --short
fi
if [ -n "$(git log --oneline origin/main..HEAD 2>/dev/null)" ]; then
  echo "WARNING: local commits not pushed:"; git log --oneline origin/main..HEAD
fi

mkdir -p "$DEST"/{solana,program,ptau,circuits-build}

echo "== Solana keypairs (names only)"
shopt -s nullglob
for f in "$HOME"/.config/solana/*.json; do
  cp "$f" "$DEST/solana/" && echo "  $(basename "$f")"
done
[ -f "$HOME/.config/solana/cli/config.yml" ] && cp "$HOME/.config/solana/cli/config.yml" "$DEST/solana/cli-config.yml"

echo "== program keypair (its pubkey is the program ID)"
for f in "$REPO"/target/deploy/*-keypair.json; do cp "$f" "$DEST/program/" && echo "  $(basename "$f")"; done

echo "== ptau"
for f in "$HOME"/ptau/*.ptau; do cp "$f" "$DEST/ptau/" && echo "  $(basename "$f")"; done

echo "== circuits/build"
cp -R "$REPO/circuits/build/." "$DEST/circuits-build/"
du -sh "$DEST/circuits-build"

echo "== other ignored files in the repository (not copied; check whether you need any)"
git ls-files --others --ignored --exclude-standard --directory \
  | grep -vE '^(node_modules|target|circuits/build|.*/node_modules|.*/target|\.anchor|test-ledger)/' || true

echo "== checksums"
(cd "$DEST" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
du -sh "$DEST"
echo "done. On the Mac: scripts/import-mac.sh /Volumes/<USB>/zkcred-export"
