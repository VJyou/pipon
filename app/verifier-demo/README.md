# p!pon verifier demo

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

Dummy cards: Tokyo · born 1999 (passes), Osaka · born 1985 (valid proof, rejected by the Tokyo-only gate), Tokyo · born 2009 (under 20: no proof can be made).
Each dummy card is stable (`circuits/build/persona-*.pem`), so its nullifier is the same across proofs.

## End-to-end with the iOS app (simulator)

The "Real iPhone app" phone mode, driven from a script: the page shows the QR link, the app (iOS simulator, dummy card
from `fetch-artifacts.sh --dev`) proves and posts back, the page verifies (Web2) or mints on devnet (Web3).

```bash
node server/mock-prover.mjs &                 # relay
VITE_BURNER=1 npx vite --host &               # burner wallet for web3.mjs
caffeinate -i node e2e/web2.mjs               # SIM="iPhone 17" CARD=tokyo20 OUT=<screenshot dir>
caffeinate -i node e2e/web3.mjs               # funds the burner with 0.05 SOL from the default Solana CLI keypair
```
Run under `caffeinate -i`: if the Mac idles into sleep mid-proof, the relay session (10 min) expires and the app gets 404.
A dummy card mints once per scope (its nullifier stays on-chain); `tokyo30` was added for a fresh first mint.
