# Pitch video: four 3-minute narration drafts

Drafts for the submission video (3 minutes at most). Each is about 330 spoken words (about 2 min 20 s at 140 words
per minute), leaving room for pauses and demo footage; D is about 370 words (about 2 min 50 s with pauses). Facts come
only from the slide notes (`docs/pitch/deck/slides/`); "open source" in D is the repository licence (GPL-3.0).
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

---

## D. C plus the world (leaks everywhere, open source, why this belongs on Solana)

[SLIDE cover]
Hi, I'm Yu Ayato, building p!pon: zero-knowledge credentials from Japan's My Number Card.

[SLIDE global]
ID documents are leaking everywhere. In September, an ID-verification vendor in the US confirmed a breach reported at
over 150 million records. The same month, a Japanese car-sharing service lost 1.6 million ID images. Every one was a
copy someone was asked to upload.

[SLIDE trend]
And laws now demand more checks: the UK, Australia, about half of US states. More checks times stored copies equals
more breaches. The way we check identity online has to change, and this is the moment.

[SLIDE whynow]
Japan can change first. From April 2027, remote KYC drops photo uploads and moves to the IC chip. Over 100 million My
Number Cards can carry a certificate signed by the national authority.

[SLIDE how]
That fixes forgery, not privacy. p!pon closes the gap. The phone reads the card and proves only the facts a service
needs: 20 or over, the prefecture, one per person. The service gets a yes, not your data.

[DEMO Web2, short]
Here it is: scan, tap the card, and in about nine and a half seconds the iPhone makes the proof. The store verifies it
in its browser and keeps only a yes, the prefecture and a store-only ID.

[DEMO Web3, short]
On Solana, zk_gate verifies the proof on-chain and records a nullifier, so a second claim from another wallet fails.

[SLIDE solana]
Why bring a Japanese card to Solana? Because the hard part is shared. The one-per-person registry and the list of
trusted government keys live on-chain: no company owns them, and anyone can read them.

[SLIDE roadmap]
And p!pon is open source. We start with the My Number Card, but ePassports and other national ID cards carry the same
kind of government-signed chip. Any team can take this code and adapt it to its own country's card, on the same Solana
registry. What we build for Japan, the whole ecosystem can use.

[SLIDE policy]
Technology alone is not enough: a zero-knowledge proof must be accepted as a lawful check. So we are co-founding an
industry association with other ZK identity projects, from any chain. If these proofs gain legal standing in Japan,
other countries get a model to follow.

[SLIDE status]
It works today, with a real card, and the iPhone app is in TestFlight beta. Stop collecting IDs. Prove the fact. p!pon.

---

## T. Technical demo (the second video, 2:00–3:00: stack, circuit, both flows, real-card result, limits)

Not a pitch draft: this is the narration for the technical demo in `video-plan.md` §2. On-screen flows use dummy or
demo cards only; the real-card result is the `realcard` slide.

[SLIDE tech]
The stack: a Circom circuit with 1.49 million constraints, proved with Groth16; on-device proving with mopro and rapidsnark; an Anchor program, zk_gate, on Solana; and a web verifier built
on snarkjs. There is no issuer server. The national certificate authority is the root of trust, and the phone does the
proving.

[SLIDE circuit]
Inside the proof, four checks happen in private: the certificate authority's signature over the certificate; the
card's own signature over a challenge bound to a wallet or a browser session; the age; and the prefecture. The public
outputs are just two facts, 20 or over and the prefecture, plus a hash of the CA key and a per-service nullifier.

[SLIDE web2flow]
First, Web2. An online store creates a one-time session and shows it as a QR code. The holder enters the card's password and taps the card: the chip signs a challenge made from the session ID,
and the phone builds the proof. The certificate never leaves the phone.

[DEMO Web2: store checkout, QR, proof, six checks turn green]
Here it is with a demo card. The store's browser verifies the proof and runs six checks: a valid proof, the same
session, a trusted CA from the list on Solana, today's date, 20 or over, and this store's scope. The store keeps a yes, the prefecture and a store-only ID.

[SLIDE web3flow]
Now Web3. A gate account on Solana holds the rules: minimum age, allowed prefectures, trusted CA keys and a scope. The
card signs a challenge made from the wallet address, so the proof only works for that wallet.

[DEMO Web3: mint, explorer transaction, same card rejected, other prefecture rejected]
One transaction does everything: zk_gate verifies the Groth16 proof with the alt_bn128 syscalls, creates the nullifier
account and mints a Metaplex Core NFT, in about 144 thousand compute units. The same card again: already claimed. A
card from another prefecture: rejected by the gate's policy.

[SLIDE realcard]
It also runs on a real My Number Card. The proof takes 3.5 seconds on a Mac with a USB reader, and about nine and
a half seconds on an iPhone 15 Pro Max. The claim was verified on devnet, and a second claim from a new wallet was
rejected.

[SLIDE limits]
Honest limits: there is no revocation check yet, because revocation lists are only available to certified verifiers,
and the trusted setup has a single contributor. Next: the Solana Attestation Service and a multi-party setup. The code is open source under GPL-3.0.
