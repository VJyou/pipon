#!/usr/bin/env bash
# Print toolchain versions. Verified on 2026-10-04:
#   rustc 1.95.0 / solana-cli 3.1.14 (platform-tools v1.52) / anchor-cli 1.0.2
#   node v22.22.3 / circom 2.2.2 / snarkjs 0.7.6
# Install (no sudo):
#   circom : git clone --depth 1 -b v2.2.2 https://github.com/iden3/circom.git ~/src/circom && cargo install --path ~/src/circom/circom
#   snarkjs: npm install -g snarkjs
for c in rustc cargo solana cargo-build-sbf anchor node npm circom; do
  printf "%-16s " "$c"
  command -v "$c" >/dev/null && "$c" --version 2>&1 | head -1 || echo "MISSING"
done
printf "%-16s " snarkjs
command -v snarkjs >/dev/null && (snarkjs --version 2>&1 | grep -m1 snarkjs || echo ok) || echo "MISSING"
