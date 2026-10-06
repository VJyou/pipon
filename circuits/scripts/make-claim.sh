#!/usr/bin/env bash
# Make a claim.json for a wallet and today's JST date, using the persistent dummy CA (build/dummy-ca.pem).
#   scripts/make-claim.sh <wallet-pubkey-base58 | 64-hex binding> <out.json>
# Also leaves snarkjs-format proof.json/public.json in build/claim-tmp/ (off-chain verification).
set -euo pipefail
cd "$(dirname "$0")/.."
B=build; C=jpki_age_region; D=$B/claim-tmp
RAPIDSNARK=${RAPIDSNARK:-$(ls -d "$HOME"/tools/rapidsnark-*/bin/prover | head -1)}  # linux-x86_64 or macOS-arm64 release
# gen_dummy_jpki.py needs Python >= 3.10 with `cryptography` (on the Mac: ~/.venvs/zkcred, see docs/setup/mac.md)
PYTHON=${PYTHON:-$( [ -x "$HOME/.venvs/zkcred/bin/python3" ] && echo "$HOME/.venvs/zkcred/bin/python3" || echo python3 )}
if [[ "$1" =~ ^[0-9a-f]{64}$ ]]; then
  WALLET_HEX=$1
else
  WALLET_HEX=$(node -e "const {PublicKey}=require('../sdk/node_modules/@solana/web3.js');console.log(Buffer.from(new PublicKey(process.argv[1]).toBytes()).toString('hex'))" "$1")
fi
export NONCE=$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')
mkdir -p $D
OUT_DIR=$D CA_KEY=$B/dummy-ca.pem WALLET=$WALLET_HEX CURRENT_DATE=$(TZ=Asia/Tokyo date +%Y%m%d) \
  "$PYTHON" scripts/gen_dummy_jpki.py >/dev/null
node $B/${C}_js/generate_witness.js $B/${C}_js/$C.wasm $D/input.json $D/w.wtns
"$RAPIDSNARK" $B/$C.zkey $D/w.wtns $D/proof.json $D/public.json
INPUT=$D/input.json node scripts/export_solana.cjs proof $D/proof.json $D/public.json "$2"
