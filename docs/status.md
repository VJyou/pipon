# Status and next steps (2026-10-07)

Read first: `CLAUDE.md`, then `docs/research/ios-plan.md`, `docs/setup/mac.md` and `app/mobile/README.md`.

## Done (Linux box)
- Circuit `circuits/src/jpki_age_region.circom` (1.49M constraints), Groth16 artifacts in `circuits/build/` (not in git).
- `zk_gate` deployed on devnet (`docs/deployments.md`); claim = Groth16 verify + nullifier PDA + Core mint (~144k CU).
- Web demo `app/verifier-demo` (simulated phone, or real iPhone via QR `pipon://prove?s=<relay session>`).
- Witness backend for mopro: **rust-witness** (graph-based circom-witnesscalc cannot build this circuit). Prover: rapidsnark.

## Done (Mac mini)
- Toolchain from `docs/setup/mac.md` §2 (Rust 1.89 + stable with iOS targets, mopro-cli 0.3.7, circom 2.2.2);
  `circuits/build/` copied and `shasum -c` OK.
- `ZkCredCore`: `swift test` passes on macOS (8/8).
- `app/mobile/ZkCredProver` (mopro crate) proves `circuits/fixtures/dummy` with the deployed zkey: Mac 3.5 s / ~1.9 GB;
  snarkjs verifies against `circuits/build/vkey.json`. Inputs are normalized because circom-prover 0.1.4 drops scalars.
  `libc` pinned to 0.2.186 for the iOS build.
- iOS app `app/mobile/ZkCredProver/ios/MoproApp.xcodeproj` (bundle id `app.pipon.ios`): ZkCredCore + Core NFC
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

## iPhone with NFC (2026-10-08) — go
- Paid team active; app installed with the real entitlements (team set locally in Xcode, not committed).
- Dummy proof: prove (rapidsnark) **9.54 s**, footprint after prove 547 MB, verify OK 0.44 s.
- Card check with the holder's own card: certificate and 256 B challenge signature read over NFC, challenge signature
  verifies (PKCS#1 v1.5, SHA-256), and the circuit layout parses (padded TBS 1472 B, within the 2048 B limit; short-form
  address). Values deliberately not recorded beyond that.
- **Web2 end to end with the real card on the iPhone** (local demo: `mock-prover.mjs` + `vite --host`, page opened at
  the Mac's LAN IP): QR → app → NFC → on-device proof → relay → all six browser checks pass (verify 333 ms).
  Gotcha: the Mac's LAN IP changed mid-session; the page must be reopened at the new IP (the QR embeds the page origin).
- **Web3 on scope 3 with the iPhone**: proof made on the phone, bound to a different wallet than the 10/7 claim; the
  gate rejects it as already claimed (nullifier on-chain). One person, one claim holds across wallets.
  Gotcha: Phantom stays on "Connecting…" on a plain-http LAN origin; open
  `http://localhost:5173/?relay=http://<Mac LAN IP>:5173` instead (the QR uses the relay origin).
- Scope 4 stays unclaimed for the video.

## Public demo on Railway (2026-10-08)
- https://pipon-demo-production.up.railway.app — replaces the Fly.io plan (no spending cap there). See
  `docs/deployments.md`. The real-iPhone mode should work from the public URL too (HTTPS, so wallets connect): not yet tested.

## Rename (2026-10-07)
- Project name **p!pon** (said "pippon"); `pipon` wherever `!` cannot go: deep link `pipon://`, bundle id
  `app.pipon.ios`, GitHub repo (rename pending). Internal code names (`ZkCredCore`, `zk_gate`, program ID) stay.
- Gate names are immutable: the demo now uses scope 5 ("p!pon Tokyo 20+", dummy CA) and scope 4 ("p!pon Japan 20+",
  J-LIS); scopes 1 and 2 keep the old name. Fresh dummy cards for first mints: `tokyo30`, `tokyo25` (used on scope 5).

## Public demo (2026-10-07)
- Temporary: Mac mini + Cloudflare quick tunnel, `PUBLIC=1` server (`app/verifier-demo/README.md`). URL changes on
  restart; plan: move to a cloud host before submission/judging. Web2 flow verified through the public URL.

## Next (end of 2026-10-07; the Mac mini was shut down, so the public tunnel URL is gone)
1. **Fly.io deploy** (`deploy/fly/`, ADR: Fly over Render). Waiting on the user: sign up + card, then
   `flyctl auth login` on the Mac. Then: `(cd app/verifier-demo && npm run build)` and
   `flyctl launch --no-deploy --copy-config --config deploy/fly/fly.toml` (app name may need changing) →
   `flyctl deploy --config deploy/fly/fly.toml --dockerfile deploy/fly/Dockerfile .` (uploads the 0.9 GB zkey).
   Until then, a temporary URL: `PUBLIC=1 IP_HEADER=cf-connecting-ip node server/mock-prover.mjs` +
   `cloudflared tunnel --url http://127.0.0.1:8787` (`app/verifier-demo/README.md`).
2. **iPhone NFC**: waiting for the paid Apple Developer Program (dev Apple ID, separate from the phone's). Then add the
   account in Xcode, switch DEVELOPMENT_TEAM (local edit, not committed), build with the real entitlements, trust the
   developer on the phone, Card check + real-card claim (use scope 3 for tests; scope 4 is for the video).
3. **Video**: pick ~10 of the 23 slides for a ≤3 min pitch cut (`docs/pitch/deck/`, online deck
   https://claude.ai/artifact/VtF16apDZiiFoRaChQZGvn); record narration (notes in each slide's `<aside>`) and screen
   captures. Each dummy card mints once per scope: make a fresh one (`circuits/scripts/make-dev-cards.sh`) or use the
   public demo's per-browser guest card.
4. Submission prep (deadline 2026-10-12 11:59pm PDT): live demo URL (Fly), repository public just before submitting.
5. Mac + USB reader backup works with a real card (`app/mobile/ZkCredMac`).

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
- Pitch deck: edit `docs/pitch/deck/slides/*.html` (or the online deck, then copy back) and rebuild the PDF with
  `node docs/pitch/deck/build-pdf.mjs`.
- Generated / large files stay out of git: `MoproiOSBindings/`, `ios/MoproApp/Circuit/` (run `ios/fetch-artifacts.sh`).

## Demo card for judges (2026-10-08)
- App: "My Number Card / Demo card" picker. The demo card is issued once per install by the demo site that sent the
  request (`POST /api/demo-card`: dummy CA, the guest dummy person, a TEST key per install) and trusted only for that
  card. Works in release builds (no `--dev` artifacts needed); only the demo gate (scope 5) and the Web2 store accept it.
- Verified: simulator → public Railway URL, Web2 all six checks pass (proof sent in 13.9 s on the simulator).
  `BASE=https://pipon-demo-production.up.railway.app CARD=demo node e2e/web2.mjs`.
- Signed device builds hang while the Mac is unattended (codesign waiting on the keychain); unsigned and simulator
  builds are fine. Build to the device or archive with someone at the Mac.
- Next for TestFlight: App Store Connect app record (bundle id `app.pipon.ios`), privacy policy URL, review notes,
  release archive with `fetch-artifacts.sh` (no `--dev`).

## Next (end of 2026-10-08; the Mac mini is shut down)
1. **TestFlight** (target: submit for Beta App Review on 10/9), at the Mac:
   App Store Connect app record (`app.pipon.ios`, name p!pon, SKU `pipon-ios`) → `ios/fetch-artifacts.sh` without
   `--dev` → archive and upload (signed builds need someone at the Mac) → paste `docs/testflight/review-notes.md`
   → external testing group with a public link. Contact: pipon.zkid@outlook.com.
2. Real iPhone on the public URL (Web2 and Web3 scope 3) — not yet tried; scope 4 stays for the video.
3. Video (≤3 min) and submission prep; deadline 2026-10-12 11:59pm PDT.
- Push from this Mac without the SSH agent: `git -c credential.helper= -c 'credential.helper=!gh auth git-credential'
  push https://github.com/VJyou/pipon.git main`.

## TestFlight (2026-10-09)
- App Store Connect record: p!pon (`app.pipon.ios`, SKU `pipon-ios`). Build 1.0 (1) uploaded from the Mac (release
  artifacts, no `--dev`; checked: no `.pem` or `dev/` in the archive). Upload worked through Xcode Organizer after
  re-signing in to the account; `xcodebuild -exportArchive` failed with "App Store Connect access is required".
- Groups: `team` (internal, automatic distribution) and `public` (external, public link, tester limit 20).
  Build 1.0 (1) submitted to Beta App Review on 2026-10-09 (Waiting for Review).
- The public link is **not** published (README, demo site, this repository): the developer name shown by TestFlight
  is the account holder's legal name. Share it only in the submission form's judges field; the link is kept outside
  the repository (App Store Connect → TestFlight → public).
- Real iPhone, TestFlight build (installed via invite), public Railway URL, holder's own card: Web2 age check passes
  all six browser checks (verify 314 ms).
