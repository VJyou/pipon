# Pitch video and technical demo: narration

Scripts for the two submission videos (3 minutes at most each). **D is the pitch script** (about 330 words, about
2 min 30 s at 140 words per minute with pauses); T is the technical demo.
The copies to paste into the voice tool are `video-script-d-tts.txt` and `video-script-t-tts.txt` (no cues, names
spelled for pronunciation).
Facts come only from the slide notes (`docs/pitch/deck/slides/`); "open source" in D is the repository licence
(GPL-3.0).
`[SLIDE x]`, `[DEMO]`, `[AVATAR only]` (the presenter alone, no slide) and `[TITLE words]` (a silent section
break: white, the words fade in and out) are visual cues, not spoken. Text under `[CUT]` is in the presenter
recording but cut from the film (the form allows 2 minutes for the pitch). Demo footage:
dummy or demo card on screen, or the holder's own
card with no personal value visible; Web3 on scope 4 (first claim) for the video.

---

## D. Pitch (leaks everywhere, why Japan now, open source, why this belongs on Solana)

[AVATAR only]
Hi, I'm Yu Ayato, building p!pon: zero-knowledge credentials from Japan's My Number Card.

[SLIDE global]
ID documents are leaking everywhere. In September, an ID-verification vendor in the US confirmed a breach reported at
over 150 million records.

[CUT]
The same month, a Japanese car-sharing service lost 1.6 million ID images. Every one was a copy someone was asked to
upload.

[SLIDE trend]
And laws now demand more checks:

[CUT]
the UK, Australia, about half of US states. More checks times stored copies equals more breaches.

[SLIDE trend]
The way we check identity online has to change, and this is the moment.

[SLIDE whynow]
Japan can change first. From April 2027, remote KYC drops photo uploads and moves to the IC chip.

[CUT]
Over 100 million My Number Cards can carry a certificate signed by the national authority.

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

[SLIDE status]
It works today, with a real card, and the iPhone app is in TestFlight beta.

[AVATAR only]
Stop collecting IDs. Prove the fact. p!pon.

---

## T. Technical demo (the second video, 2:00–3:00: stack, circuit, both flows, real-card result, limits)

Not a pitch draft: this is the narration for the technical demo in `video-plan.md` §2. On-screen flows use dummy or
demo cards or the real-card recordings (see `video-plan.md` for what is shown and blurred).

[SLIDE tech]
The stack: a Circom circuit with 1.49 million constraints, proved with Groth16; on-device proving with mopro and
rapidsnark; an Anchor program, zk_gate, on Solana; and a web verifier built
on snarkjs. There is no issuer server. The national certificate authority is the root of trust, and the phone does the
proving.

[SLIDE circuit]
Inside the proof, four checks happen in private: the certificate authority's signature over the certificate; the
card's own signature over a challenge bound to a wallet or a browser session; the age; and the prefecture. The public
outputs are just two facts, 20 or over and the prefecture, plus a hash of the CA key and a per-service nullifier.

[SLIDE web2flow]
First, Web2. An online store creates a one-time session and shows it as a QR code. The holder enters the card's
password and taps the card: the chip signs a challenge made from the session ID,
and the phone builds the proof. The certificate never leaves the phone.

[DEMO Web2: store checkout, QR, proof, six checks turn green]
Here it is with a real My Number Card. The store's browser verifies the proof and runs six checks: a valid proof, the
same session, a trusted CA from the list on Solana, today's date, 20 or over, and this store's scope. The store keeps
a yes, the prefecture and a store-only ID.

[SLIDE web3flow]
Now Web3. A gate account on Solana holds the rules: minimum age, allowed prefectures, trusted CA keys and a scope. The
card signs a challenge made from the wallet address, so the proof only works for that wallet.

[DEMO Web3: mint, explorer transaction]
One transaction does everything: zk_gate verifies the Groth16 proof with the alt_bn128 syscalls, creates the nullifier
account and mints a Metaplex Core NFT, in about 144 thousand compute units.

[SLIDE web3]
The same card again: already claimed. A card from another prefecture: rejected by the gate's policy.

[SLIDE realcard]
Timings with the real card: the proof takes 3.5 seconds on a Mac with a USB reader, and about nine and
a half seconds on an iPhone 15 Pro Max. The claim was verified on devnet, and a second claim from a new wallet was
rejected.

[SLIDE limits]
Honest limits: there is no revocation check yet, because revocation lists are only available to certified verifiers,
and the trusted setup has a single contributor. Next: revocation through a certified operator, a multi-party setup and
an audit before mainnet, and the App Store and Android.

---

## P. Product demo (the form's demo video: up to 3 minutes, the live product, no slide deck)

How the product is put together, told over the live recordings: the app, the check a website runs, the Solana
program. No slides. Replaces T for the submission (the form asks for the live product, not a technical walkthrough).
Each `[DEMO name]` cue is one shot cut from the four recordings (whole screen, or a close-up of part of it), held
for as long as its sentence takes.

[AVATAR only]
p!pon has three parts: an iPhone app that reads your My Number Card, a check that any website can run in its own
browser page, and a Solana program for one-per-person gates. Here is each of them, live.

[DEMO web2a: the whole demo page, store at checkout]
This is an online store selling sake. At checkout it needs one fact: is the buyer 20 or over?

[DEMO web2b: the QR code appears]
The store shows a QR code.

[DEMO web2c: iPhone camera, then the request in the app]
I scan it with my iPhone, and the p!pon app shows who is asking and what they will learn.

[DEMO web2d: card tap]
I tap my real My Number Card on the phone.

[DEMO web2e: proving on the phone, proof sent]
The app reads the chip and builds a zero-knowledge proof on the device, so the card data never leaves the phone.

[DEMO web2f: close-up of the six checks]
The store's page checks the proof by itself: no p!pon server, no account, no wallet.

[DEMO web2g: close-up of what the store received and never sees]
It learns three things: 20 or over, the prefecture, and an ID that only this store sees. It never gets my name, my
birthday, my address or a photo of my card.

[DEMO web3a: close-up of the gate and its rules]
The second place a proof can go is Solana. This gate keeps its rules on-chain: 20 or over, and one claim per person.

[DEMO web3b: request, card tap, mint]
I connect a wallet, the app makes a proof that only works for that wallet, and I press Mint.

[DEMO web3c: close-up of the minted result]
Our program, zk_gate, verifies the proof on-chain, records that this card has claimed, and mints the NFT, all in one
transaction.

[DEMO web3d: close-up of the claim count and the note on a second claim]
The same card cannot claim here again from any wallet, and nobody keeps a list of people.

[DEMO web3e: close-up of the trust-list check]
The store and the gate read the same list of trusted government keys from Solana, so both trust the same root.

[AVATAR only]
The iPhone app is in TestFlight beta, with a demo card for people who do not have a My Number Card. The web demo is
live, and all the code is open source. p!pon: prove the fact, not your ID.
