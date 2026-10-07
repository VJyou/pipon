# p!pon iPhone app

- `ZkCredCore/` — platform-independent Swift package: X.509/DER parsing, circuit input builder
  (byte-for-byte identical to `circuits/scripts/gen_dummy_jpki.py`), JPKI APDUs, CA selection and signature pre-checks.
  Tested on Linux and macOS: `cd ZkCredCore && swift test`.
- `ZkCredApp/` — app sources and settings used by the Xcode project:
  - `Sources/JPKIReader.swift` — Core NFC session: verify signing password, read the signing certificate, sign the challenge.
  - `Sources/CardCheckView.swift` — reads the holder's own card and shows only `CertificateLayout` and the challenge check.
  - `ZkCredApp.entitlements`, `Info.plist` — NFC (ISO 7816, JPKI AID), increased memory limit, `pipon://` deep link.
- `ZkCredProver/` — mopro 0.3.7 crate (`rustwitness` + `rapidsnark`), see `docs/research/ios-plan.md`.
  - `ZkCredProver/ios/MoproApp.xcodeproj` — the app (bundle id `app.pipon.ios`); links `ZkCredCore` as a local
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

Signing: the NFC Tag Reading capability needs a paid Apple Developer Program team; a free Personal Team cannot sign it.
To try the prover on a device with a free team, build with an entitlements file that keeps only
`increased-memory-limit`, then run the dummy proof:
```bash
xcodebuild -project ios/MoproApp.xcodeproj -scheme MoproApp -configuration Release \
  -destination 'id=<device udid>' -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=<team id> CODE_SIGN_ENTITLEMENTS=<no-nfc.entitlements> build
xcrun devicectl device install app --device <udid> <path to MoproApp.app>
xcrun devicectl device process launch --console --device <udid> app.pipon.ios -- -autoprove
```
(Trust the developer once on the phone: Settings → General → VPN & Device Management.)

Flow: request (binding, scope, nonce) → password → NFC read + card signature → `TrustAnchors` picks the J-LIS CA and
checks the card signature → `CircuitInput.json(...)` → mopro proof → claim to the web demo / Solana.
Nothing personal leaves the phone; only `CertificateLayout` (sizes/offsets) may be logged while debugging.
