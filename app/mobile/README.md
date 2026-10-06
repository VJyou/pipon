# zkCredentials iPhone app

- `ZkCredCore/` — platform-independent Swift package: X.509/DER parsing, circuit input builder
  (byte-for-byte identical to `circuits/scripts/gen_dummy_jpki.py`), JPKI APDUs, CA selection and signature pre-checks.
  Tested on Linux and macOS: `cd ZkCredCore && swift test`.
- `ZkCredApp/` — app sources and settings used by the Xcode project:
  - `Sources/JPKIReader.swift` — Core NFC session: verify signing password, read the signing certificate, sign the challenge.
  - `Sources/CardCheckView.swift` — reads the holder's own card and shows only `CertificateLayout` and the challenge check.
  - `ZkCredApp.entitlements`, `Info.plist` — NFC (ISO 7816, JPKI AID), increased memory limit, `zkcred://` deep link.
- `ZkCredProver/` — mopro 0.3.7 crate (`rustwitness` + `rapidsnark`), see `docs/research/ios-plan.md`.
  - `ZkCredProver/ios/MoproApp.xcodeproj` — the app (bundle id `app.zkcredentials.ios`); links `ZkCredCore` as a local
    package and compiles `ZkCredApp/Sources`.

Build:
```bash
cd ZkCredProver && mopro build --platforms ios --mode release \
  --architectures aarch64-apple-ios aarch64-apple-ios-sim --no-auto-update
rm -rf ios/MoproiOSBindings && cp -R MoproiOSBindings ios/   # generated, not in git
ios/fetch-artifacts.sh                                      # zkey + dummy input, not in git
open ios/MoproApp.xcodeproj                                 # select your team, run on the iPhone
```
In the simulator, launch with `-autoprove` to prove the dummy fixture on start (results also go to stdout).

Flow: request (binding, scope, nonce) → password → NFC read + card signature → `TrustAnchors` picks the J-LIS CA and
checks the card signature → `CircuitInput.json(...)` → mopro proof → claim to the web demo / Solana.
Nothing personal leaves the phone; only `CertificateLayout` (sizes/offsets) may be logged while debugging.
