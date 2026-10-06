#!/bin/sh
# Copy what the app bundles but git does not hold into MoproApp/Circuit/ (ignored):
#   the deployed zkey, the dummy fixture input, and the J-LIS signing CA certificates.
#   --dev  also bundles the dummy cards (circuits/scripts/make-dev-cards.sh) and their TEST keys,
#          for proving without a card in the simulator. Never use --dev for a build you hand out.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
out="$here/MoproApp/Circuit"
rm -rf "$out"
mkdir -p "$out"
cp "$root/circuits/build/jpki_age_region.zkey" "$out/jpki_age_region.zkey"
cp "$root/circuits/fixtures/dummy/input.json" "$out/dummy_input.json"
cp "$root"/circuits/fixtures/jlis/signca0[123].cer "$out/"
if [ "${1:-}" = "--dev" ]; then
  mkdir -p "$out/dev"
  for der in "$root"/circuits/build/dev-cards/*.der; do
    name=$(basename "$der" .der)
    cp "$der" "$out/dev/"
    [ "$name" = dummy-ca ] || cp "$root/circuits/build/persona-$name.pem" "$out/dev/$name.pem"
  done
  echo "dev cards bundled (test keys): $(ls "$out/dev" | tr '\n' ' ')"
fi
ls -lh "$out"
