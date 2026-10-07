# Status and next steps (2026-10-07)

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

## Done (2026-10-06/07)
- App flow: deep link → request → card (NFC, or dummy card in dev) → checks → proof → relay. Web demo end to end with the
  iOS simulator (`app/verifier-demo/e2e/`): Web2 all checks pass; Web3 mints on the demo gate (scope 1).
- Real-card gate on devnet: scope 2, age 20+, all prefectures, J-LIS signca02/03 (`docs/deployments.md`). The web demo
  has a gate selector (Web3) and trusts both gates' CA lists (Web2).

## iPhone (2026-10-07, iPhone 15 Pro Max)
- A free Personal Team **cannot sign the NFC Tag Reading capability** (Xcode: "Personal development teams … do not
  support the NFC Tag Reading capability"). `increased-memory-limit` is fine. Paid Apple Developer Program enrollment
  requested; NFC on the device waits for it.
- Dummy proof on the device with a no-NFC build (entitlements override at build time, not committed): prove
  (rapidsnark) **9.07 s**, verify OK 0.39 s, footprint after prove 471 MB, no jetsam.
  Build: `xcodebuild … -allowProvisioningUpdates DEVELOPMENT_TEAM=<team> CODE_SIGN_ENTITLEMENTS=<no-nfc.entitlements>`,
  install with `devicectl device install app`, run with `devicectl device process launch --console … -- -autoprove`.

## Next
1. [local] iPhone: connect + trust, Xcode Apple ID/team, Developer Mode (`docs/setup/mac.md` §6). Then on the device:
   dummy proof time/memory; Card check on the holder's own card (assumptions 1–4 in `ios-plan.md`); a real-card claim
   on the scope-2 gate. Find out whether a free personal team can sign the NFC entitlement.
2. Demo video plan and recording (deadline 2026-10-12 PDT); English UI and README.
3. Backup (decided 2026-10-06: iPhone stays primary): macOS + USB PC/SC reader path reusing ZkCredCore and the prover.
4. Go/no-go on 2026-10-08.

## Gotchas
- Use **the same zkey** as the deployed verifying key (copied via USB). A new setup means a new `vk.rs` and a program upgrade.
- Keypairs were moved from the Linux box to the Mac on 2026-10-06 (`scripts/export-linux.sh` / `import-mac.sh`):
  `~/.config/solana/zkcred-devnet.json` (upgrade authority `7LQS…`), `id.json`, and `target/deploy/zk_gate-keypair.json`
  (program ID `AsTt…`). Never through git. Never run `anchor keys sync`.
- Mac Solana tooling: Solana CLI 4.1.2, Anchor via avm **1.0.2** (matches `anchor-lang` in `programs/zk_gate/Cargo.toml`).
  `anchor build` passes; `programs/zk_gate/tests/fixtures/mpl_core.so` is dumped from devnet
  (`solana program dump -u devnet CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d <path>`).
- Dummy CA / persona keys (`circuits/build/*.pem`) are test-only and stay out of git.
- Real card: the holder's own card only; never log, save or commit the certificate or any personal value.
- Commit as `VJyou <37763328+VJyou@users.noreply.github.com>` (repo-local git config), messages in English.
- Generated / large files stay out of git: `MoproiOSBindings/`, `ios/MoproApp/Circuit/` (run `ios/fetch-artifacts.sh`).
