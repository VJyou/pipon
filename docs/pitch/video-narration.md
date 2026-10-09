# Pitch video: three 3-minute narration drafts

Drafts for the submission video (3 minutes at most). Each is about 380 spoken words (about 2 min 45 s at 140 words
per minute), leaving room for pauses and demo footage. Facts come only from the slide notes (`docs/pitch/deck/slides/`).
`[SLIDE x]` and `[DEMO]` are visual cues, not spoken. Demo footage: dummy or demo card on screen, or the holder's own
card with no personal value visible; Web3 on scope 4 (first claim) for the video.

---

## A. Problem first (breach → lesson → product → proof it works)

[SLIDE cover]
Hi, I'm Yu Ayato, and this is p!pon: zero-knowledge credentials from the IC chip in Japan's My Number Card.

[SLIDE global]
Every month brings another ID leak. In September a US ID-verification vendor confirmed a breach of over 150 million
records. The same month in Japan, a car-sharing service lost 1.6 million images of driver's licences. Every one of
these was a copy someone was asked to upload.

[SLIDE trend]
And checks are multiplying: the UK, Australia, half of US states, and in Japan remote KYC moves to the IC chip in April
2027. More checks times stored copies equals more breaches.

[SLIDE lesson]
The lesson is simple: data you never collect cannot leak.

[SLIDE how]
IC chips solve authenticity. Zero-knowledge proofs solve privacy. Your phone reads the card, checks the government
signature inside a zero-knowledge proof, and sends only the facts: over 20, lives in a prefecture, hasn't claimed
before. No name, no birthday, no address, no ID image — and no issuer server.

[DEMO Web2: QR → iPhone → tap card → "Age verified"]
Here is an online store selling sake. I tap "Verify age with p!pon", scan the QR code, and tap my card. The proof is
made on the iPhone in about nine and a half seconds, and the store's browser verifies it in a third of a second. The
store learns: 20 or over, the prefecture, and a pseudonymous ID for this store only.

[DEMO Web3: claim on devnet, then a second wallet rejected]
On Solana, the same proof is bound to a wallet. zk_gate verifies it on-chain, records a nullifier and mints an NFT in
one transaction. A second claim from a new wallet is rejected: one per person, without anyone keeping a list of people.

[SLIDE solana]
Solana gives us a shared "one per person" registry that no company has to own, and an on-chain trust list any website
can read.

[SLIDE roadmap]
Next: the App Store and Android, a checkout SDK for stores, the Solana Attestation Service, and AI agents that can show
a verified human behind them.

[SLIDE status]
It works today, with a real My Number Card, and the iPhone app is in TestFlight beta. Stop collecting IDs. Prove the
fact. p!pon.

---

## B. Demo first (show it working, then explain why)

[DEMO Web2, from the first frame]
This online store sells sake, so it must know I'm 20 or over. Today it would ask for a photo of my ID. Instead I tap
"Verify age with p!pon", scan the QR code with my iPhone, enter my card's password and tap my My Number Card.

[DEMO proof finishing, store shows "Age verified"]
In about nine and a half seconds the phone makes a zero-knowledge proof. The store checks it in a third of a second
and learns three things: 20 or over, my prefecture, and an ID that only this store sees. It never sees my name, my
birthday, my address or my card.

[SLIDE cover]
I'm Yu Ayato, and this is p!pon: zero-knowledge credentials from the IC chip in Japan's My Number Card.

[SLIDE how]
IC chips solve authenticity: the certificate is signed by the national authority. Zero-knowledge proofs solve privacy:
the signature is checked inside the proof, on the phone, so the data never leaves it. There is no issuer server and
nothing to leak.

[DEMO Web3: claim, then second wallet rejected]
The same proof works on Solana. Bound to my wallet, it is verified on-chain by our program, zk_gate, which records a
nullifier and mints an NFT in one transaction. If I try again from another wallet, it fails. One person, one claim —
and nobody holds a list of people.

[SLIDE global]
Why does this matter? Because ID copies leak. In September alone, a US vendor confirmed over 150 million records
exposed, and a Japanese car-sharing service lost 1.6 million licence images. Data you never collect cannot leak.

[SLIDE whynow]
And Japan is ready: from April 2027, remote KYC moves from photos to the IC chip, and over 100 million My Number Cards
are already in people's hands.

[SLIDE roadmap]
Next: the App Store and Android, a drop-in checkout SDK, the Solana Attestation Service for reusable credentials, and
AI agents that carry proof of a verified human into x402 payments.

[SLIDE status]
It works today on devnet with a real card, and the app is in TestFlight beta. Stop collecting IDs. Prove the fact.
p!pon.

---

## C. Japan as the model (why now, why us, the bigger vision)

[SLIDE cover]
Hi, I'm Yu Ayato, building p!pon: zero-knowledge credentials from Japan's My Number Card.

[SLIDE whynow]
Japan is about to change how it checks identity online. From April 2027, remote KYC drops photo uploads and moves to
the IC chip. Over 100 million My Number Cards each carry a certificate signed by the national authority.

[SLIDE breach]
That fixes forgery, not privacy. Two weeks ago, one of Japan's largest car-sharing services lost 1.6 million uploaded
ID images. Every service that keeps a copy of your ID is a breach waiting to happen.

[SLIDE how]
p!pon closes that gap. The phone reads the card and proves only the facts a service needs: 20 or over, the prefecture,
one per person. The service gets a yes, not your data.

[DEMO Web2, short]
Here it is: scan, tap the card, and in about nine and a half seconds the iPhone makes the proof. The store verifies it
in its browser and keeps only a yes, the prefecture and a store-only ID.

[DEMO Web3, short]
On Solana, zk_gate verifies the proof on-chain and records a nullifier, so a second claim from another wallet fails.

[SLIDE compete]
Why not passport-based tools? In Japan only about 18% of people hold a valid passport, while 84.5% hold a My Number
Card — and passports cannot prove where you live.

[SLIDE policy]
Technology alone is not enough. A zero-knowledge proof has to be accepted as a lawful way to check age or residence.
So we are co-founding an industry association with other ZK identity projects, from any chain, to write guidelines and
work with regulators. If ZK proofs gain legal standing in Japan, other countries get a model to follow.

[SLIDE roadmap]
From there: the App Store and Android, a checkout SDK, AI agents that act for a verified human, and ePassports, so the
same proof and the same Solana registry can work for travellers from any country.

[SLIDE status]
It works today, with a real card, and the iPhone app is in TestFlight beta. Stop collecting IDs. Prove the fact. p!pon.
