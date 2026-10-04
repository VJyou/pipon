# iPhone app plan (go/no-go 2026-10-08)

Goal: read the JPKI signing certificate over NFC, have the card sign a challenge bound to the wallet / session,
generate the Groth16 proof **on the iPhone**, and hand the claim to the web demo (deep link / QR).

## Stack (proposal)
- **SwiftUI native app** (not Expo): Core NFC and mopro both have first-class Swift support; fewer bridges in 4 days.
- **mopro 0.3.7** (`mopro-ffi` → `Mopro.xcframework` + `mopro.swift`) with `circom-prover` features
  `witnesscalc` (native witness) + `rapidsnark` (native prover). Fallback: `rustwitness` + `arkworks`.
- Inputs are flat 1-D arrays, which mopro's JSON input format supports.
- zkey (928 MB) bundled for development; for TestFlight download on first launch and cache.

## Card protocol (JPKI-AP, ISO 7816 over Core NFC)
| Step | APDU | Notes |
|---|---|---|
| Select JPKI-AP | `00 A4 04 0C 0A D3 92 F0 00 26 01 00 00 00 01` | AID must be listed in `com.apple.developer.nfc.readersession.iso7816.select-identifiers` |
| Verify signing password | SELECT EF `001B`, `VERIFY` with the 6–16 char password | 5 wrong tries lock the certificate — show remaining tries first |
| Read signing certificate | SELECT EF `0001`, `READ BINARY` (chunked) | DER X.509; never logged or persisted |
| Sign the challenge | SELECT EF `001A` (signing key), `COMPUTE DIGITAL SIGNATURE` over DigestInfo(SHA-256(msg)) | msg = SHA-256(wallet ‖ nonce) |
(EF ids from the open-source readers cited in `THIRD_PARTY_NOTICES.md`; verify on the device.)

## Assumptions the real card must confirm (record sizes/offsets only, never values)
1. TBSCertificate ≤ 2048 bytes after SHA padding (else recompile with larger `maxTbsLen` → new zkey → upgrade `zk_gate`).
2. SAN otherName values are UTF8String; DOB is `EYYYYMMDD` with a Gregorian year; address starts with the prefecture.
3. Address length encoding: short or `0x81` long form (the `0x82` form is not handled yet).
4. Card signature is PKCS#1 v1.5 with SHA-256 DigestInfo.

## Schedule
| Day | Target |
|---|---|
| 10/5 | Mac setup; mopro template app builds and proves the **dummy** fixture on the iPhone (time, memory) |
| 10/6 | Core NFC: read the signing certificate, check assumptions 1–4 |
| 10/7 | Card challenge signature + real proof on device; J-LIS CA gate on devnet |
| 10/8 | Hand-off to the web demo (deep link/QR) → **go/no-go** |

## Real-card safety
- Your own card only; certificate and witness stay in memory; nothing personal is written to disk, logs or git.
- The gate for real cards trusts the J-LIS signing CA (`caKeyHash` of signca02/03, see `rsa-spike.md`).
