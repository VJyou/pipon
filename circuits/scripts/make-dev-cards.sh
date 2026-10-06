#!/usr/bin/env bash
# Dummy "cards" for the iOS app in development: one certificate per web-demo persona, issued by the persistent dummy CA
# (build/dummy-ca.pem, trusted by the scope-1 gate on devnet) for the persona's key (build/persona-*.pem).
# Output: build/dev-cards/{<persona>.der, dummy-ca.der}. Test data only; never in git or a release build.
#   PYTHON=~/.venvs/zkcred/bin/python3 scripts/make-dev-cards.sh
set -euo pipefail
cd "$(dirname "$0")/.."
PY=${PYTHON:-python3}
O=build/dev-cards
mkdir -p $O
# Same personas and serials as app/verifier-demo/server/mock-prover.mjs, plus tokyo30 (app only: a fresh card
# for showing a first successful mint; create its key with `openssl genrsa -out build/persona-tokyo30.pem 2048`).
i=0
for p in tokyo20:419990401:東京都千代田区霞が関一丁目１番１号:13 \
         osaka40:319850715:大阪府大阪市北区中之島一丁目３番２０号:27 \
         tokyo17:420090401:東京都新宿区西新宿二丁目８番１号:13 \
         tokyo30:419950520:東京都渋谷区神南一丁目１番１号:13; do
  IFS=: read -r name dob addr code <<< "$p"
  T=$(mktemp -d)
  OUT_DIR=$T CA_KEY=build/dummy-ca.pem USER_KEY=build/persona-$name.pem SERIAL=$((1000 + i)) \
    DOB=$dob ADDR=$addr PREFECTURE_CODE=$code "$PY" scripts/gen_dummy_jpki.py >/dev/null
  cp "$T/user.der" "$O/$name.der"
  cp "$T/ca.der" "$O/dummy-ca.der"
  rm -rf "$T"
  i=$((i + 1))
done
ls "$O"
