# zkcred-mac (backup path)

The iPhone app's request flow on a Mac, with the My Number Card in a USB PC/SC smart card reader (contact or
contactless, CCID) instead of the iPhone's NFC. Same APDUs (`ZkCredCore.JPKIAPDU`), same checks, same circuit inputs,
same deployed zkey; the proof is made by the Rust prover in `ZkCredProver` (`src/bin/prove.rs`, rapidsnark).

Build:
```bash
(cd ../ZkCredProver && cargo build --release --bin prove)
../ZkCredProver/ios/fetch-artifacts.sh            # zkey + J-LIS CAs (add --dev for the dummy cards)
swift build -c release
# CryptoTokenKit only serves binaries signed with the smartcard entitlement
codesign -f -s - --entitlements zkcred-mac.entitlements .build/release/zkcred-mac
```

Use:
```bash
.build/release/zkcred-mac readers                                   # readers and whether a card is present
.build/release/zkcred-mac prove '<zkcred://prove?s=...>'            # asks for the signing password
.build/release/zkcred-mac prove '<zkcred://prove?s=...>' --dev tokyo20   # dummy card, no reader
```
The deep link is the text under the QR code in the web demo ("Real iPhone app" phone mode).
End to end against the web demo: `app/verifier-demo/e2e/web2-mac.mjs` (`CARD=reader` for the real card).

The certificate stays in memory and goes to the prover over a pipe; only the proof, public signals and nonce are sent.
Measured on a Mac mini (dummy card): proof 4.0 s, Web2 check passes end to end.
