# Third-party notices

zkCredentials is licensed under GPL-3.0 (see `LICENSE`). It builds on the following open-source work.

| Component | License | Used in | How |
|---|---|---|---|
| [circomlib](https://github.com/iden3/circomlib) | GPL-3.0 | `circuits/` | Poseidon, comparators, bit utilities, SHA-256 compression (compiled into the circuit) |
| [@zk-email/circuits](https://github.com/zkemail/zk-email-verify) | MIT | `circuits/` | `Sha256Bytes`, `RSAVerifier65537`, `VarShiftLeft`, `PoseidonLarge` (compiled into the circuit) |
| [circom](https://github.com/iden3/circom) | GPL-3.0 | build tool | Circuit compiler |
| [snarkjs](https://github.com/iden3/snarkjs) | GPL-3.0 | `circuits/`, `app/verifier-demo/` | Groth16 setup, proving, in-browser verification |
| [circomlibjs](https://github.com/iden3/circomlibjs) | GPL-3.0 | `circuits/scripts/` | Poseidon hash of CA keys |
| [rapidsnark](https://github.com/iden3/rapidsnark) | LGPL-3.0 | build tool | Fast native prover |
| [groth16-solana](https://github.com/Lightprotocol/groth16-solana) | MIT | `programs/zk_gate` | On-chain Groth16 verification via alt_bn128 syscalls |
| [Anchor](https://github.com/solana-foundation/anchor) | Apache-2.0 | `programs/zk_gate` | Solana program framework |
| [mpl-core](https://github.com/metaplex-foundation/mpl-core) | Metaplex NFT Open Source License v1.0 | `programs/zk_gate` | Minting Core assets via CPI |
| [LiteSVM](https://github.com/LiteSVM/litesvm) | Apache-2.0 | `programs/zk_gate/tests` | Program tests |
| [@solana/web3.js](https://github.com/solana-foundation/solana-web3.js), wallet-adapter | MIT / Apache-2.0 | `sdk/`, `app/verifier-demo/` | Client |
| [Perpetual Powers of Tau](https://github.com/privacy-scaling-explorations/perpetualpowersoftau) (`ppot_0080_21`) | public ceremony output | `circuits/` (not committed) | Phase-1 parameters for the Groth16 setup |

Implementation references (no code copied): [myna-card](https://github.com/soltia48/myna-card), [jpki/myna](https://github.com/jpki/myna) for the My Number Card file layout.

Trust anchors: `circuits/fixtures/jlis/signca0{1,2,3}.cer` are the public self-signed certificates of the JPKI signing CA,
published by J-LIS at https://www.jpki.go.jp/ca/ca_rules3.html (fingerprints checked against J-LIS's published list).

The Groth16 phase-2 contribution used in the demo is a single local contribution and is **not** suitable for production.
