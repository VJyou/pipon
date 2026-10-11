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
| 0:00–0:10 | Title: "p!pon — prove the fact, not your ID" | Hi, I'm Yu Ayato. I'm building p!pon: zero-knowledge credentials from the IC chip in Japan's My Number Card. |
| 0:10–0:45 | News headlines (no logos): car-sharing service, 6.6M accounts, 1.6M driver's-licence images; police reissuing licences | Two weeks ago, one of Japan's largest car-sharing services was breached: about 6.6 million member accounts, and 1.6 million images of driver's licences and other ID documents that members had uploaded to sign up. Police are now reissuing licences. And it is not an isolated case: in 2025, listed companies in Japan alone reported leaks affecting over 30 million people. |
| 0:45–1:05 | "Collect → store → leak" crossed out → "Verify → forget" | The lesson is simple: data you never collect cannot leak. Every service that keeps a copy of your ID is a breach waiting to happen. This is the turning point — companies will have to stop holding personal data wherever they can. p!pon makes that possible. |
| 1:05–1:25 | "April 2027" timeline: photo upload → IC chip reading; "100M+ cards" | Japan is already moving identity checks from photos to the IC chip: from April 2027, remote KYC drops photo uploads. Over 100 million My Number Cards are in people's hands, each able to carry a certificate signed by the national authority. |
| 1:25–1:55 | Diagram: card → phone (proof) → website / Solana | IC chips solve authenticity. Zero-knowledge proofs solve privacy. The phone reads the card, checks the government signature inside a zero-knowledge proof, and sends only the facts: over 20, lives in a prefecture, hasn't claimed before. The service gets a yes — no name, no birthday, no address, no ID image. No issuer server, nothing to leak. |
| 1:55–2:15 | Use cases grid: age-gated shops, sign-up checks, one-per-person drops and airdrops, Sybil-resistant votes, AI-agent delegation | Who is it for? Every service that asks for an ID today only to learn one fact: age-gated online stores, sign-ups that need "a real, unique person", one-per-person drops, DAO votes, and AI agents acting for a verified human. It is not a replacement for legal KYC — it's for everything else. |
| 2:15–2:30 | Why Solana: nullifier registry, on-chain Groth16, Solana Attestation Service | Solana makes "one per person" a public registry: a per-service nullifier, a Groth16 proof verified on-chain in about 144k compute units, and a mint in the same transaction. |
| 2:30–2:50 | Status + vision | It works today on devnet, with a real My Number Card end to end. Next: an iPhone app in TestFlight, attestations on Solana, and the same model for other national ID chips. Stop collecting IDs. Prove the fact. p!pon. |

## 2. Technical demo (target 2:45)

Screen recording + voice-over. Dummy cards on screen (dummy CA, dummy people) unless noted.

| Time | Screen | Voice-over / points |
|---|---|---|
| 0:00–0:20 | Architecture diagram (README "How it works") | Stack: Circom circuit (1.49M constraints, Groth16), on-device proving with mopro + rapidsnark, Anchor program `zk_gate` on Solana, web verifier with snarkjs. |
| 0:20–0:50 | Circuit walkthrough (slides) | Inside the proof: RSA-2048/SHA-256 check of the J-LIS CA signature over the certificate; the card's signature over a challenge bound to the wallet or browser session; date-of-birth + N years ≤ today; address prefix = prefecture; output = CA-key hash + per-scope nullifier. Nothing else is public. |
| 0:50–1:30 | Web demo, **Web2 · Age check** (an online store selling sake, at checkout): QR → phone proves → six checks turn green | No wallet, no signup. The shop verifies the proof in the browser in ~200 ms and checks the issuer CA against the trust list stored on Solana. It learns: 20+, the prefecture, and a pseudonymous ID for this shop only. Point at "What it never sees". |
| 1:30–2:15 | **Web3 · Gated mint**: connect wallet → proof → Mint → explorer tx | The proof is bound to the wallet. `zk_gate` verifies Groth16 with the alt_bn128 syscalls, stores the nullifier in a PDA and mints a Metaplex Core NFT in one transaction (~144k CU). Then: same card again → "Already claimed"; a card from another prefecture → rejected by the gate policy. |
| 2:15–2:35 | One slide: "Tested on a real My Number Card" — timings + devnet tx links (`docs/deployments.md`, scope-3 claim and the rejected second claim). No card, no holder data, no holder wallet on screen | The same flow runs on a real My Number Card: proof in 3.5 s on a Mac with a USB reader, claim verified on devnet, and a second claim from a new wallet rejected. On an iPhone 15 Pro Max the proof takes 9 s on device. |
| 2:35–2:45 | Limits + next | Honest limits: no revocation check yet (lists are only for certified verifiers), single-contributor trusted setup. Next: iPhone NFC in TestFlight, Solana Attestation Service. |

### Shot list (what to record)
1. Web2 flow with the simulated phone (dummy card `tokyo20`) — or with the iPhone app + dev card once signed.
2. Web3 flow on gate 1 with a fresh dummy card (each dummy card mints once per scope: make a new one with
   `circuits/scripts/make-dev-cards.sh` before recording), then the same card again (rejected), then `osaka40` (rejected).
3. Explorer pages for the mint tx (compute units visible).
4. Terminal: `zkcred-mac prove … --dev tokyo20` with the proving time.
5. iPhone screen recording of the app (after the paid team is approved).

## Decision: real card in the video (2026-10-07)
**A**: every on-screen flow uses dummy cards; the real-card result is one slide with timings and devnet tx links.
No card, no screen showing the holder's prefecture, nullifier or wallet. Scope 2 stays unclaimed.

## Decision: AI presenter and voice (2026-10-10)
**Pitch video**: the founder's own HeyGen digital twin (face + cloned voice) reads the English script, over the slides.
**Technical demo**: screen recordings with the cloned voice only, no avatar.

- Source footage is recorded in Japanese (about 2 minutes, plain background); the script is the reviewed English
  narration, not machine translation.
- Needs the HeyGen Creator plan (no watermark, 1080p, videos longer than 1 minute).
- Decided 2026-10-11: go ahead with the AI presenter. The official rules have no provision against AI-generated
  presenters (`docs/legal/hackathon-rules-check.md` has no entry); this is our reading, not a confirmation from the
  organisers.
- Decided 2026-10-11: the pronunciation in the generated pitch video is accepted as it is (product name, founder's
  name, zk_gate).
- Decided 2026-10-11 (pitch video demo footage, replaces decision A of 10-07 for this video): the real-card
  recordings are used. Shown as they are: the prefecture (Tokyo), the shortened wallet address, the on-screen
  "Proof sent" time (it differs from the narrated proof time). Blurred: the store-only pseudonymous ID and the photo
  thumbnail in the iPhone camera. No footage of the rejected second claim. Scope 4 is now claimed.
- Submission form (seen 2026-10-11) differs from the workshop notes above: **pitch video up to 2 minutes**; demo video up
  to 3 minutes and it "should show the live product, not a slide deck, not a code walkthrough"; both as YouTube, Loom
  or Vimeo links.
- Decided 2026-10-11: the pitch video is final at 1 min 58 s (draft D with its `[CUT]` cues, no section breaks). The
  demo video follows section P of `video-narration.md` (product structure over live recordings), not section T.
- Pitch script: draft D in `video-narration.md`; the copy for the voice tool is `video-script-d-tts.txt`.
