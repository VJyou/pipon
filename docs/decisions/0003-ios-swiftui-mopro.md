# ADR-0003: Build the iPhone app natively in SwiftUI with mopro

- Date: 2026-10-04
- Status: Accepted

## Context
The iPhone app must read the JPKI signing certificate over NFC, have the card sign a challenge and generate a
1.49M-constraint Groth16 proof on device. Deadline 2026-10-12 PDT, go/no-go on 10/8. CLAUDE.md had Expo/React Native as a placeholder.

## Options
1. Expo / React Native + react-native-nfc-manager + mopro React Native bindings
2. SwiftUI + Core NFC + mopro Swift bindings (`Mopro.xcframework`)

## Decision
Option 2: SwiftUI native, Core NFC (ISO 7816), mopro 0.3.7 with `circom-prover` (`witnesscalc` + `rapidsnark`, fallback `rustwitness` + `arkworks`).

## Consequences
- Fewer bridges to debug in four days; Core NFC and mopro both document Swift first.
- iOS only (fine for the hackathon; Android would be a separate Kotlin app or a later RN port).
- The app ships the exact zkey whose verifying key is deployed on devnet (copied from the Linux build, checked with SHA256SUMS).
