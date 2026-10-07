# Video plan (draft, 2026-10-07)

Two videos for the Colosseum submission ([submission workshop notes](https://blog.colosseum.com/perfecting-your-hackathon-submission/)):

| Video | Limit | Purpose |
|---|---|---|
| Pitch | **≤ 3:00** (hard limit) | The *why*: team, problem, who it is for, validation, vision. Voice-over on slides is fine. |
| Technical demo | **2:00–3:00** | The *how*: features, stack, design choices, Solana integration, on-chain logic, architecture. |

Rules that apply (`docs/legal/hackathon-rules-check.md`, CLAUDE.md): English only; **no real card and no real personal
data on screen**; no Colosseum logos. Voice-over pace ≈ 150 words/min → ~420 words for 2:50.

Open items are marked **[TBD]**. Numbers and sources: `docs/research/market-numbers.md`.

---

## 1. Pitch video (target 2:50)

| Time | Slide / visual | Voice-over |
|---|---|---|
| 0:00–0:15 | Title: "zkCredentials — prove the fact, not your ID" | Hi, I'm Yu Ayato, co-founder of Japan Blockchain Week. I'm building zkCredentials: zero-knowledge credentials from the IC chip in Japan's My Number Card. |
| 0:15–0:45 | A shop form asking for an ID photo → name, birthday, address highlighted; only "20+" is needed | To buy a drink online, join a one-per-person drop, or get into an event, services ask for a photo of your ID. They need one bit — "over 20", "a real, unique person" — and they collect your name, birthday and address. Most of them have no legal duty to. And that data leaks: in 2025, listed companies in Japan alone reported leaks affecting over 30 million people. Data you never collect cannot leak. |
| 0:45–1:10 | "April 2027" timeline: photo upload → IC chip reading | Japan is already moving identity checks to the chip. From April 2027, remote KYC under the anti–money-laundering law drops photo uploads in favour of reading the IC chip. Over 100 million My Number Cards are in people's hands today, and each chip can carry a certificate signed by the national authority. |
| 1:10–1:45 | Diagram: card → phone (proof) → website / Solana | IC chips solve authenticity. Zero-knowledge proofs solve privacy. The phone reads the card, checks the government signature inside a zero-knowledge proof, and sends only the facts: over 20, lives in a prefecture, hasn't claimed before. No issuer server, no ID copy, nothing to leak. |
| 1:45–2:10 | Use cases grid: age gates, one-per-person mints/airdrops, events, Sybil-resistant votes, AI-agent delegation | Who is it for? Anyone who over-collects ID today without needing to: age-gated shops, NFT and token drops that want one per person, event tickets, DAO votes, and soon AI agents acting for a verified human. It is not a replacement for legal KYC — it's for everything else. |
| 2:10–2:30 | Why Solana: nullifier registry, on-chain Groth16, Solana Attestation Service, x402 | Solana makes "one per person" a public registry: a per-service nullifier, a Groth16 proof verified on-chain in about 144k compute units, and a mint in the same transaction. |
| 2:30–2:50 | Status + vision | It works today on devnet, with a real My Number Card end to end. **[TBD — confirm before recording]** No user interviews yet; candidate wording: "As an event organiser at Japan Blockchain Week, I see this problem first-hand: event check-in and one-per-person drops — that is where I want to pilot first." Next: an iPhone app in TestFlight, attestations on Solana, and the same model for other national ID chips. zkCredentials — prove the fact, not your ID. |

## 2. Technical demo (target 2:45)

Screen recording + voice-over. Dummy cards on screen (dummy CA, dummy people) unless noted.

| Time | Screen | Voice-over / points |
|---|---|---|
| 0:00–0:20 | Architecture diagram (README "How it works") | Stack: Circom circuit (1.49M constraints, Groth16), on-device proving with mopro + rapidsnark, Anchor program `zk_gate` on Solana, web verifier with snarkjs. |
| 0:20–0:50 | Circuit walkthrough (slides) | Inside the proof: RSA-2048/SHA-256 check of the J-LIS CA signature over the certificate; the card's signature over a challenge bound to the wallet or browser session; date-of-birth + N years ≤ today; address prefix = prefecture; output = CA-key hash + per-scope nullifier. Nothing else is public. |
| 0:50–1:30 | Web demo, **Web2 · Age check**: QR → phone proves → six checks turn green | No wallet, no signup. The shop verifies the proof in the browser in ~200 ms and checks the issuer CA against the trust list stored on Solana. It learns: 20+, the prefecture, and a pseudonymous ID for this shop only. Point at "What it never sees". |
| 1:30–2:15 | **Web3 · Gated mint**: connect wallet → proof → Mint → explorer tx | The proof is bound to the wallet. `zk_gate` verifies Groth16 with the alt_bn128 syscalls, stores the nullifier in a PDA and mints a Metaplex Core NFT in one transaction (~144k CU). Then: same card again → "Already claimed"; a card from another prefecture → rejected by the gate policy. |
| 2:15–2:35 | Real-card evidence **[TBD, see decision below]** | Same flow on a real My Number Card: proof in 3.5 s on a Mac with a USB reader, claim on devnet, second claim rejected. iPhone: 9 s on-device proving. |
| 2:35–2:45 | Limits + next | Honest limits: no revocation check yet (lists are only for certified verifiers), single-contributor trusted setup. Next: iPhone NFC in TestFlight, Solana Attestation Service. |

### Shot list (what to record)
1. Web2 flow with the simulated phone (dummy card `tokyo20`) — or with the iPhone app + dev card once signed.
2. Web3 flow on gate 1 with a fresh dummy card (each dummy card mints once per scope: make a new one with
   `circuits/scripts/make-dev-cards.sh` before recording), then the same card again (rejected), then `osaka40` (rejected).
3. Explorer pages for the mint tx (compute units visible).
4. Terminal: `zkcred-mac prove … --dev tokyo20` with the proving time.
5. iPhone screen recording of the app (after the paid team is approved).

## Decision needed: real card in the video
CLAUDE.md says no real card and no real personal data in the video. Options:
- **A (recommended)**: all on-screen flows use dummy cards; the real-card result is one slide with the devnet tx
  links (`docs/deployments.md`) and timings — no card, no screen with a prefecture or wallet tied to the holder.
- **B**: record the real-card terminal + Web3 mint on scope 2 (gate shows "all prefectures", the UI shows no
  personal value), card itself never on camera. Uses the card's one claim on scope 2.
- **C**: no mention of the real card.
