#!/usr/bin/env bash
# Compile, setup (Groth16) and prove the JPKI age/region circuit with the dummy fixture.
#   scripts/build.sh            -> compile + witness + setup + prove + verify
#   PTAU=/path/to.ptau scripts/build.sh
# Requires: circom, node deps (npm i), a ptau with >= 2^21 powers (PSE ppot_0080_21.ptau).
set -euo pipefail
cd "$(dirname "$0")/.."
B=build
C=jpki_age_region
PTAU=${PTAU:-$HOME/ptau/ppot_0080_21.ptau}
RAPIDSNARK=${RAPIDSNARK:-$(ls -d "$HOME"/tools/rapidsnark-linux-x86_64-*/bin/prover 2>/dev/null | head -1 || true)}
SNARKJS="node --max-old-space-size=12000 node_modules/.bin/snarkjs"
mkdir -p $B
t() { local s=$(date +%s.%N); "$@"; echo "  [$(echo "$(date +%s.%N) - $s" | bc) s] $*" >&2; }

python3 scripts/gen_prefectures.py
[ -f fixtures/dummy/input.json ] || python3 scripts/gen_dummy_jpki.py

t circom src/$C.circom --r1cs --wasm --O2 -l node_modules -o $B | grep -E 'constraints|wires'
t node $B/${C}_js/generate_witness.js $B/${C}_js/$C.wasm fixtures/dummy/input.json $B/$C.wtns

if [ ! -f $B/$C.zkey ]; then
  t $SNARKJS groth16 setup $B/$C.r1cs "$PTAU" $B/${C}_0.zkey >/dev/null
  t $SNARKJS zkey contribute $B/${C}_0.zkey $B/$C.zkey -n="spike" -e="$(head -c 32 /dev/urandom | xxd -p)" >/dev/null
  rm -f $B/${C}_0.zkey
  $SNARKJS zkey export verificationkey $B/$C.zkey $B/vkey.json >/dev/null
fi

t $SNARKJS groth16 prove $B/$C.zkey $B/$C.wtns $B/proof.json $B/public.json
t $SNARKJS groth16 verify $B/vkey.json $B/public.json $B/proof.json
if [ -n "$RAPIDSNARK" ]; then
  t "$RAPIDSNARK" $B/$C.zkey $B/$C.wtns $B/proof_rs.json $B/public_rs.json
  t $SNARKJS groth16 verify $B/vkey.json $B/public_rs.json $B/proof_rs.json
fi
ls -l $B/$C.zkey $B/$C.r1cs $B/${C}_js/$C.wasm | awk '{print "  " $5/1e6 " MB  " $9}'
