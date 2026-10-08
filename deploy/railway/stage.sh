#!/usr/bin/env bash
# Public web demo on Railway. Railway's `railway up` uploads a directory, and the files the image needs (zkey, dummy
# keys, built page) are git-ignored, so this script stages exactly those files plus the Fly.io Dockerfile into a
# separate directory and deploys from there:
#   (cd app/verifier-demo && npm run build)
#   deploy/railway/stage.sh <dir> && (cd <dir> && railway up --no-gitignore)
# The dummy CA and persona keys are test keys for dummy cards; no real card data is involved.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
out="${1:?usage: stage.sh <output dir>}"
rm -rf "$out" && mkdir -p "$out"

copy() { mkdir -p "$out/$(dirname "$1")" && cp -R "$root/$1" "$out/$1"; }
for f in circuits/build/jpki_age_region.zkey circuits/build/jpki_age_region_js circuits/build/vkey.json \
  circuits/build/dummy-ca.pem circuits/build/persona-tokyo20.pem circuits/build/persona-osaka40.pem \
  circuits/build/persona-tokyo17.pem circuits/scripts sdk/package.json sdk/package-lock.json sdk/src \
  app/verifier-demo/server app/verifier-demo/dist; do
  copy "$f"
done

# Same image as Fly.io; Railway's edge puts the client address in X-Real-IP and injects PORT at runtime.
sed -e 's/IP_HEADER=fly-client-ip/IP_HEADER=x-real-ip/' -e 's/on Fly\.io/on Railway/' \
  "$root/deploy/fly/Dockerfile" > "$out/Dockerfile"
du -sh "$out"
