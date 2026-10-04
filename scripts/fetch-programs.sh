#!/usr/bin/env bash
# Dump external programs the LiteSVM tests load (not committed).
set -euo pipefail
cd "$(dirname "$0")/.."
D=programs/zk_gate/tests/fixtures
solana program dump CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d $D/mpl_core.so --url mainnet-beta
