# TestFlight: texts for App Store Connect (draft)

Draft texts for the external TestFlight build of the p!pon iPhone app (bundle id `app.pipon.ios`).
Placeholders in brackets are still open.

## App information

- Name: p!pon
- Subtitle (30 characters max): Prove facts, not your ID
- Primary category: Utilities
- Privacy policy URL: https://pipon-demo-production.up.railway.app/privacy.html

## Test information

**Beta app description**

> p!pon proves a fact about you, such as "age 20 or over", from the IC chip of a Japanese My Number Card, without
> handing over the data on the card. The phone reads the card over NFC and makes a zero-knowledge proof on the device;
> the website only receives the proof and the facts it asked for. No My Number Card? Choose "Demo card" to try the same
> flow with a dummy card.

**What to test**

> 1. On a computer, open https://pipon-demo-production.up.railway.app and choose "Web2 · Age check".
> 2. Set "Phone" to "Real iPhone app" and press "Verify age with p!pon". A QR code appears.
> 3. Scan the QR code with the iPhone camera. p!pon opens with the request.
> 4. Choose "Demo card" (or "My Number Card" if you have one) and press "Prove". The proof takes about 10–15 seconds.
> 5. The website shows "Age verified" and what the store received.
> Web3: the "Web3 · Gated mint" tab does the same with a Solana devnet wallet; a second claim by the same card is
> rejected.

**Feedback email:** [CONTACT EMAIL]

**Sign-in required:** No

## Notes for the reviewer (Beta App Review)

> p!pon is a hackathon project (Solana Colosseum). It reads the Japanese My Number Card (JPKI signing certificate)
> over NFC, which a reviewer outside Japan will not have, so the app includes a "Demo card": the demo website issues a
> dummy card (fictional person, test key) to the app, and every step after the card read is the same as with a real
> card, including the on-device proof.
>
> Steps: open https://pipon-demo-production.up.railway.app on a computer → "Web2 · Age check" → Phone: "Real iPhone
> app" → "Verify age with p!pon" → scan the QR code with the iPhone camera → in p!pon choose "Demo card" → "Prove".
> The website shows "Age verified" after about 10–15 seconds. No account or sign-in is needed.
>
> NFC is used only to read the user's own card after they enter the card's signing password. The card data never
> leaves the phone; only the proof and the requested facts are sent to the website in the QR code.

## Export compliance

- The app uses encryption only through Apple's operating system (HTTPS) and for zero-knowledge proofs and signature
  checks, which authenticate data and do not encrypt it. Expected answer: exempt; set
  `ITSAppUsesNonExemptEncryption = NO` in the build so the question is not asked per build. [confirm before submitting]

## App privacy (for the App Store later; TestFlight does not need it)

- Data collected: none linked to the user. The proof's facts (age threshold met, prefecture code, a per-service
  pseudonymous ID) go to the site that asked, not to us. See the privacy policy.
