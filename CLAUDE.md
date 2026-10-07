# p!pon (pipon; formerly zkCredentials) — Solana Colosseum Hackathon

## One-line definition
ZK credentials for Web2 and Web3 that use the cryptographic authenticity of government-issued IC chips
(My Number Card, etc.) as the root of trust and prove "only the facts needed" without handing over personal data.

## Core message
- IC chips solve authenticity. Zero-knowledge credentials solve privacy.
- Why now: from April 2027, remote identity verification under Japan's Act on Prevention of Transfer of Criminal
  Proceeds (犯収法) moves from photo upload to IC-chip reading.

## Settled direction
- **Positioning**: not a replacement for statutory KYC. The target is where ID is over-collected without a legal duty
  (age checks, one per person, Sybil resistance, events, metaverse, AI-agent delegation).
- **No issuer (client-side proving)**: the device reads the IC chip, the issuer signature is verified inside the ZK
  circuit, and only attributes (e.g. age>=20, unique_human) are output. Anon Aadhaar / Self style.
- **Never handle the Individual Number (My Number).**
- **Why Solana**: nullifier registry (one per person across services), on-chain Groth16 via alt_bn128,
  Solana Attestation Service, integration with agent payments (x402 etc.).

## Open decisions (when decided, write an ADR in docs/decisions/ and update this list)
- ~~MVP use case~~ → **Decided: age + prefecture + one per person → gated mint** (ADR-0002)
- ZK stack: Circom + Groth16 (groth16-solana) for now. Spike against Noir etc. only if needed
- ~~Root of trust~~ → **Decided: JPKI (signing certificate = attributes, user-authentication certificate = uniqueness)** (ADR-0001, docs/legal/proof-sources.md)
- Revocation (J-LIS revocation data requires certification; for now "only certificates issued within N days")
- ~~Mobile~~ → **Decided: native SwiftUI + Core NFC + mopro** (ADR-0003)
- Hackathon deadline: **2026-10-12 11:59pm PDT (= 2026-10-13 15:59 JST)** (official rules §5, docs/legal/hackathon-rules-check.md)
  - iPhone app (NFC read + on-device proof): **go/no-go on 10/8**. If not ready, submit the web demo and limit the iPhone to NFC reading
  - 10/9–10/12: submission prep (English, video, publish the repository)

## Repository layout
- circuits/   ZK circuits (src, test, fixtures)
- programs/   Solana programs (Anchor)
- app/mobile/ iPhone app (NFC read, proof generation)
- app/verifier-demo/ verifier-side demo (Web2 site and Web3 gate)
- sdk/        SDK for verifiers
- docs/decisions/ ADRs
- docs/research/  competitive and technical research
- docs/pitch/     pitch material
- docs/legal/     primary-source notes on AML/CFT rules and JPKI
- inbox/      photos / PDFs sent from the iPhone (move to the right place after processing)

## Submission requirements (official rules)
- **All submitted content in English** (§12): README, video, demo UI, docs. Write new documents in English
- Licence **GPL-3.0** (circomlib dependency). Publish the repository just before submitting
- No real cards or real personal data in the video or the repository. Do not use Colosseum logos

## Working rules (remote operation)
- **Talk to the user in Japanese**; everything committed to the repository is in English.
- **Keep reports short enough to read on a phone**: conclusion → changes → next decisions, in a few lines. Write long output to a file and give the path.
- **When a decision is needed, ask with 2–3 options.** Do not make large changes of direction on your own.
- **Commit small**: meaningful units, specific commit messages **in English** (since 2026-10-04, for the English requirement).
- **Notify when long jobs finish** (builds, setup, benchmarks).
- **Do not run anything that needs sudo**; show the command and stop (no password input remotely).
- **No real personal data in the repository or tests.** Tests use self-generated dummy certificates and keys.
- Do not read or commit private keys, .env files or Solana keypairs.
- Record regulatory and specification claims in docs/legal/ with primary-source URLs, separating facts from inferences.
