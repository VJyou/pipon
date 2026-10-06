# Status and next steps (2026-10-06)

Read first: `CLAUDE.md`, then `docs/research/ios-plan.md`, `docs/setup/mac.md` and `app/mobile/README.md`.

## Done (Linux box)
- Circuit `circuits/src/jpki_age_region.circom` (1.49M constraints), Groth16 artifacts in `circuits/build/` (not in git).
- `zk_gate` deployed on devnet (`docs/deployments.md`); claim = Groth16 verify + nullifier PDA + Core mint (~144k CU).
- Web demo `app/verifier-demo` (simulated phone, or real iPhone via QR `zkcred://prove?s=<relay session>`).
- Witness backend for mopro: **rust-witness** (graph-based circom-witnesscalc cannot build this circuit). Prover: rapidsnark.

## Done (Mac mini)
- Toolchain from `docs/setup/mac.md` §2 (Rust 1.89 + stable with iOS targets, mopro-cli 0.3.7, circom 2.2.2);
  `circuits/build/` copied and `shasum -c` OK.
- `ZkCredCore`: `swift test` passes on macOS (8/8).
- `app/mobile/ZkCredProver` (mopro crate) proves `circuits/fixtures/dummy` with the deployed zkey: Mac 3.5 s / ~1.9 GB;
  snarkjs verifies against `circuits/build/vkey.json`. Inputs are normalized because circom-prover 0.1.4 drops scalars.
  `libc` pinned to 0.2.186 for the iOS build.
- iOS app `app/mobile/ZkCredProver/ios/MoproApp.xcodeproj` (bundle id `app.zkcredentials.ios`): ZkCredCore + Core NFC
  reader + Card check screen (layout only) + dummy proof. Simulator: proof verifies, public inputs identical to snarkjs.
  Builds for iphoneos unsigned. **Not yet run on the iPhone** (not connected; no signing identity yet).

## Next
1. [local] iPhone: connect + trust, Xcode Apple ID/team, Developer Mode (`docs/setup/mac.md` §6). Then run the app:
   dummy proof time/memory on device; Card check on the holder's own card (assumptions 1–4 in `ios-plan.md`).
   Find out whether a free personal team can sign the NFC entitlement.
2. Connect the full flow in the app: deep link → request → password + NFC → `TrustAnchors` (J-LIS CA certs) →
   `CircuitInput.json` → proof → relay → web demo; then the J-LIS-CA gate on devnet.
3. Backup (decided 2026-10-06: iPhone stays primary): macOS + USB PC/SC reader path reusing ZkCredCore and the prover.
   Needs a reader model that works with the My Number Card on macOS.
4. Go/no-go on 2026-10-08.

## Gotchas
- Use **the same zkey** as the deployed verifying key (copied via USB). A new setup means a new `vk.rs` and a program upgrade.
- The devnet upgrade-authority keypair lives only on the Linux box (`~/.config/solana/zkcred-devnet.json`). Do program
  upgrades there, or move the keypair by USB yourself — never through git.
- Dummy CA / persona keys (`circuits/build/*.pem`) are test-only and stay out of git.
- Real card: the holder's own card only; never log, save or commit the certificate or any personal value.
- Commit as `VJyou <37763328+VJyou@users.noreply.github.com>` (repo-local git config), messages in English.
- Generated / large files stay out of git: `MoproiOSBindings/`, `ios/MoproApp/Circuit/` (run `ios/fetch-artifacts.sh`).
