# p!pon

**Prove only the facts you need — "20 or over", "lives in Tokyo", "hasn't claimed before" — from the IC chip of
Japan's My Number Card, without handing over your ID.** Verifiable by any website in the browser and on Solana.

> IC chips solve authenticity. Zero-knowledge credentials solve privacy.

Pitch and business overview: [docs/pitch/deck/pipon-pitch.pdf](docs/pitch/deck/pipon-pitch.pdf)

## Why now
- Japan is moving identity checks to IC chips: from April 2027, remote KYC under the Act on Prevention of Transfer of
  Criminal Proceeds drops photo-upload methods in favour of reading the chip ([JAFIC Q&A](https://www.npa.go.jp/sosikihanzai/jafic/hourei/data/25062402qa.pdf)).
- Most services that collect ID photos have **no legal duty to**: age gates, one-per-person drops, event tickets,
  Sybil resistance. They take name, birthday and address to learn a single bit.
- The chip already carries a certificate signed by the national CA (J-LIS). A zero-knowledge proof can check that
  signature and reveal only the attribute.

p!pon is **not** a replacement for statutory KYC. It targets the places where ID is over-collected.

## How it works
```
 My Number Card ──NFC──▶ iPhone app ──proof (only facts)──▶ website (browser verify)
 (J-LIS-signed cert)      Groth16 on device              └──▶ Solana program (verify + nullifier + mint)
```
1. **Read**: the phone reads the JPKI signing certificate over NFC (the holder enters the card's signing password)
   and has the card sign a challenge bound to the wallet or browser session.
2. **Prove** (on the phone): a Circom circuit checks the J-LIS CA signature (RSA-2048/SHA-256) over the certificate,
   the card's signature over the challenge, `date of birth + N years ≤ today`, and that the address starts with the
   chosen prefecture. It outputs only a CA-key hash and a **per-service nullifier**.
3. **Verify**:
   - Web2: any site verifies the Groth16 proof in the browser (~200 ms), checking the CA against a trust list on Solana.
   - Web3: the `zk_gate` Solana program verifies the proof with `alt_bn128` syscalls, records the nullifier in a PDA
     (one claim per person per service) and mints a Metaplex Core NFT — **~144k compute units**.

The nullifier differs per service (`scope`), so services cannot link the same person. No issuer server is involved:
the national CA is the root of trust, and the phone does the proving.

## What's in this repo
| Path | What |
|---|---|
| `circuits/` | `jpki_age_region.circom` (1.49M constraints), dummy-certificate generator, witness tests, Solana export |
| `programs/zk_gate/` | Anchor program: gate config, Groth16 verify, nullifier PDA, Core mint; LiteSVM tests |
| `app/verifier-demo/` | Web demo: Web3 gated mint and Web2 age check; simulated phone or the real iPhone app via QR |
| `app/mobile/` | iPhone app (SwiftUI + Core NFC + mopro): deep link → read card → on-device proof → send; `ZkCredCore` Swift package (tested) |
| `sdk/` | Minimal JS client and devnet demo script |
| `docs/` | Decisions (ADR), research, legal notes, deployment record |

## Status (devnet)
- `zk_gate`: [`AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK`](https://explorer.solana.com/address/AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK?cluster=devnet)
- Two gates: a demo gate for **dummy** certificates (dummy CA, dummy people), and a gate that trusts the real J-LIS
  signing CAs (age 20+, all prefectures). See `docs/deployments.md`.
- End to end with dummy certificates: web demo → iPhone app (simulator) → proof → browser verify or on-chain verify
  and mint; replays and other prefectures rejected.
- Proving with rapidsnark: **9.1 s on an iPhone 15 Pro Max** (on device, ~470 MB), 3.5 s on a Mac mini.

## Run the demo
```bash
# circuit artifacts (needs the 2^21 Perpetual Powers of Tau file, see circuits/scripts/build.sh)
cd circuits && npm i && scripts/build.sh && cd ..
cd sdk && npm i && cd ..
cd app/verifier-demo && npm i
node server/mock-prover.mjs &   # simulated phone + relay
npm run dev                     # http://localhost:5173 (devnet wallet)
```
The page can also hand the request to the iPhone app over a QR code (`pipon://` link); see `app/verifier-demo/README.md`
and `app/mobile/README.md`.
Program tests: `anchor build && scripts/fetch-programs.sh && cargo test -p zk_gate`.
Swift core tests: `cd app/mobile/ZkCredCore && swift test`.

## Limits and honesty
- Revocation: certificate revocation lists are only available to government-certified verifiers, so proofs do not
  check revocation yet. Mitigation: accept only recent certificates; production would go through a certified
  platform operator.
- Legal: verifying the J-LIS signature on device without revocation data appears outside the certification
  requirement, but this needs confirmation from the regulator (`docs/legal/proof-sources.md`).
- The Groth16 setup uses a single local phase-2 contribution: demo only.
- No real personal data is in this repository; all tests use generated dummy certificates.

## License
GPL-3.0 (the circuit links circomlib). See `THIRD_PARTY_NOTICES.md`.
