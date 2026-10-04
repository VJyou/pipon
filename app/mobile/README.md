# zkCredentials iPhone app

- `ZkCredCore/` — platform-independent Swift package: X.509/DER parsing, circuit input builder
  (byte-for-byte identical to `circuits/scripts/gen_dummy_jpki.py`), JPKI APDUs, CA selection and signature pre-checks.
  Tested on Linux and macOS: `cd ZkCredCore && swift test`.
- `ZkCredApp/` — iOS sources added to the Xcode app target:
  - `JPKIReader.swift` — Core NFC session: verify signing password, read the signing certificate, sign the challenge.
  - `ZkCredApp.entitlements`, `Info.additions.plist` — NFC (ISO 7816, JPKI AID) and increased memory limit.
- Proving: mopro 0.3.7 (`rustwitness` + `rapidsnark`), see `docs/research/ios-plan.md`.

Flow: request (binding, scope, nonce) → password → NFC read + card signature → `TrustAnchors` picks the J-LIS CA and
checks the card signature → `CircuitInput.json(...)` → mopro proof → claim to the web demo / Solana.
Nothing personal leaves the phone; only `CertificateLayout` (sizes/offsets) may be logged while debugging.
