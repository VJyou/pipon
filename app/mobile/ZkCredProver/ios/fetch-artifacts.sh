#!/bin/sh
# Copy the circuit artifacts the app bundles (not in git): the deployed zkey and the dummy fixture input.
# Run after `mopro build` / `mopro update` and whenever circuits/build changes.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
mkdir -p "$here/MoproApp/Circuit"
cp "$root/circuits/build/jpki_age_region.zkey" "$here/MoproApp/Circuit/jpki_age_region.zkey"
cp "$root/circuits/fixtures/dummy/input.json" "$here/MoproApp/Circuit/dummy_input.json"
ls -lh "$here/MoproApp/Circuit"
