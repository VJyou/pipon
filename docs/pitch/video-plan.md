# Video plan (draft, 2026-10-07)

Two videos for the Colosseum submission ([submission workshop notes](https://blog.colosseum.com/perfecting-your-hackathon-submission/)):

| Video | Limit | Purpose |
|---|---|---|
| Pitch | **≤ 3:00** (hard limit) | The *why*: team, problem, who it is for, validation, vision. Voice-over on slides is fine. |
| Technical demo | **2:00–3:00** | The *how*: features, stack, design choices, Solana integration, on-chain logic, architecture. |

Rules that apply (`docs/legal/hackathon-rules-check.md`, CLAUDE.md): English only; **no real card and no real personal
data on screen**; no Colosseum logos. Voice-over pace ≈ 150 words/min → ~420 words for 2:50.

Open items are marked **[TBD]**. Story: the September 2026 Times Car breach (driver's-licence images) as the turning point
towards services that do not hold personal data. Numbers and sources: `docs/research/market-numbers.md`.

---

## 1. Pitch video (target 2:50)

| Time | Slide / visual | Voice-over |
|---|---|---|
| 0:00–0:10 | Title: "zkCredentials — prove the fact, not your ID" | Hi, I'm Yu Ayato. I'm building zkCredentials: zero-knowledge credentials from the IC chip in Japan's My Number Card. |
| 0:10–0:45 | News headlines (no logos): car-sharing service, 6.6M accounts, 1.6M driver's-licence images; police reissuing licences | Two weeks ago, one of Japan's largest car-sharing services was breached: about 6.6 million member accounts, and 1.6 million images of driver's licences and other ID documents that members had uploaded to sign up. Police are now reissuing licences. And it is not an isolated case: in 2025, listed companies in Japan alone reported leaks affecting over 30 million people. |
| 0:45–1:05 | "Collect → store → leak" crossed out → "Verify → forget" | The lesson is simple: data you never collect cannot leak. Every service that keeps a copy of your ID is a breach waiting to happen. This is the turning point — companies will have to stop holding personal data wherever they can. zkCredentials makes that possible. |
| 1:05–1:25 | "April 2027" timeline: photo upload → IC chip reading; "100M+ cards" | Japan is already moving identity checks from photos to the IC chip: from April 2027, remote KYC drops photo uploads. Over 100 million My Number Cards are in people's hands, each able to carry a certificate signed by the national authority. |
| 1:25–1:55 | Diagram: card → phone (proof) → website / Solana | IC chips solve authenticity. Zero-knowledge proofs solve privacy. The phone reads the card, checks the government signature inside a zero-knowledge proof, and sends only the facts: over 20, lives in a prefecture, hasn't claimed before. The service gets a yes — no name, no birthday, no address, no ID image. No issuer server, nothing to leak. |
| 1:55–2:15 | Use cases grid: age-gated shops, sign-up checks, one-per-person drops and airdrops, Sybil-resistant votes, AI-agent delegation | Who is it for? Every service that asks for an ID today only to learn one fact: age-gated shops, sign-ups that need "a real, unique person", one-per-person drops, DAO votes, and AI agents acting for a verified human. It is not a replacement for legal KYC — it's for everything else. |
| 2:15–2:30 | Why Solana: nullifier registry, on-chain Groth16, Solana Attestation Service | Solana makes "one per person" a public registry: a per-service nullifier, a Groth16 proof verified on-chain in about 144k compute units, and a mint in the same transaction. |
| 2:30–2:50 | Status + vision | It works today on devnet, with a real My Number Card end to end. Next: an iPhone app in TestFlight, attestations on Solana, and the same model for other national ID chips. Stop collecting IDs. Prove the fact. zkCredentials. |

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
