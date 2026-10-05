# Status and next steps (handoff, 2026-10-05)

Read first: `CLAUDE.md`, then `docs/research/ios-plan.md` and `docs/setup/mac.md`.

## Done (Linux box)
- Circuit `circuits/src/jpki_age_region.circom` (1.49M constraints), Groth16 artifacts in `circuits/build/` (not in git).
- `zk_gate` deployed on devnet (`docs/deployments.md`); claim = Groth16 verify + nullifier PDA + Core mint (~144k CU).
- Web demo `app/verifier-demo` (simulated phone, or real iPhone via QR `zkcred://prove?s=<relay session>`).
- `app/mobile/ZkCredCore` Swift package (circuit input builder identical to the Python generator, CA selection,
  card-signature check, APDUs, deep link) — `swift test` passes on Linux. `app/mobile/ZkCredApp/JPKIReader.swift` (Core NFC) not yet compiled.
- Witness backend for mopro: **rust-witness** (graph-based circom-witnesscalc cannot build this circuit). Prover: rapidsnark.

## Next on the Mac (go/no-go 2026-10-08)
1. Finish `docs/setup/mac.md` (toolchain, repo, USB copy of `circuits/build/transfer/`, `shasum -c`).
2. `cd app/mobile/ZkCredCore && swift test` on macOS.
3. mopro app (`mopro init` → circom adapter with `rustwitness` + `rapidsnark`) proving the **dummy** fixture
   `circuits/fixtures/dummy/input.json` on the iPhone 15 Pro Max; record time and memory.
4. Add `ZkCredCore` + `ZkCredApp/*` to the Xcode target (entitlements, Info.plist additions); read the real signing
   certificate and print only `CertificateLayout` (sizes/offsets) to check the circuit's assumptions.
5. Real proof on device → relay → web demo (Web2) and a J-LIS-CA gate on devnet (Web3).

## Gotchas
- Use **the same zkey** as the deployed verifying key (copied via USB). A new setup means a new `vk.rs` and a program upgrade.
- The devnet upgrade-authority keypair lives only on the Linux box (`~/.config/solana/zkcred-devnet.json`). Do program
  upgrades there, or move the keypair by USB yourself — never through git.
- Dummy CA / persona keys (`circuits/build/*.pem`) are test-only and stay out of git.
- Real card: the holder's own card only; never log, save or commit the certificate or any personal value.
- Commit as `VJyou <37763328+VJyou@users.noreply.github.com>` (repo-local git config), messages in English.
