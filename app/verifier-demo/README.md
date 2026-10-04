# zkCredentials verifier demo

Web demo for the pitch: a simulated phone proves facts from a (dummy) My Number Card, and two services verify them.

- **Web3 · Gated mint** — wallet → proof bound to the wallet → `zk_gate` on devnet verifies Groth16, records the nullifier and mints a Metaplex Core NFT. A second claim with the same card is rejected; a card from another prefecture is rejected by the gate policy.
- **Web2 · Age check** — no wallet: the browser verifies the proof with snarkjs and checks the issuer CA against the trust list stored on Solana. The shop gets age ≥ 20, the prefecture and a shop-scoped pseudonymous ID — nothing else.

The phone is simulated by `server/mock-prover.mjs`, which issues dummy JPKI certificates (dummy CA, dummy people) and proves with the real circuit.

## Run

Prerequisites: circuit artifacts in `circuits/build/` (`cd circuits && npm i && scripts/build.sh`, needs the 2^21 ptau) and `npm i` in `sdk/` (used by `make-claim.sh`).

```bash
cd app/verifier-demo
npm i
node server/mock-prover.mjs        # terminal 1, port 8787
npm run dev                        # terminal 2, http://localhost:5173
```

Use a devnet wallet (Phantom etc. set to devnet) with a little SOL. For automated tests only, `VITE_BURNER=1 npm run dev` adds an in-browser burner wallet.

Dummy cards: 東京都・1999年生 (passes), 大阪府・1985年生 (valid proof, rejected by the Tokyo-only gate), 東京都・2009年生 (under 20: no proof can be made).
Each dummy card is stable (`circuits/build/persona-*.pem`), so its nullifier is the same across proofs.
