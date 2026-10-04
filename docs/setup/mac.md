# Mac mini setup (iOS development)

Target: Mac mini (Apple silicon, 24 GB / 512 GB), iPhone 15 Pro Max. Steps marked **[local]** need you at the Mac
(password / GUI); the rest can be done remotely by Claude Code once it is running.

## 1. Base system [local]
1. Update macOS, sign in with your Apple ID.
2. Install **Xcode** (latest) from the App Store, open it once, install the iOS platform when asked.
3. Terminal:
   ```bash
   xcode-select --install          # command line tools
   sudo xcodebuild -license accept
   ```
4. Install Homebrew (https://brew.sh) — asks for your password.

## 2. Toolchain
```bash
brew install cmake nasm node git tmux gh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
cargo install mopro-cli@0.3.7
git clone --depth 1 -b v2.2.2 https://github.com/iden3/circom.git ~/src/circom && cargo install --path ~/src/circom/circom
```

## 3. GitHub access [local]
```bash
gh auth login        # GitHub.com → SSH → generate a new key → login with browser (or device code from your phone)
git clone git@github.com:VJyou/zkcredentials.git ~/zkcredentials
cd ~/zkcredentials
git config user.name VJyou
git config user.email 37763328+VJyou@users.noreply.github.com
```

## 4. Claude Code + remote control [local]
Install Claude Code following https://code.claude.com/docs, then from the repo:
```bash
scripts/rc.sh        # tmux session "zk"; press SPACE for the QR code, connect from the phone
```

## 5. Circuit artifacts
The Mac needs the **same** `jpki_age_region.zkey` that produced the verifying key deployed on devnet
(re-running the setup creates a different key and would require redeploying `zk_gate`).
The bundle is prepared on the Linux box at `~/zkcredentials/circuits/build/transfer/` (894 MB: zkey, wasm, vkey.json,
dummy CA / dummy persona keys for the demo, `SHA256SUMS`). Copy it with a USB stick (exFAT or FAT32 is fine; largest file 928 MB), then on the Mac:
```bash
mkdir -p ~/zkcredentials/circuits/build && cp /Volumes/<USB>/transfer/* ~/zkcredentials/circuits/build/
cd ~/zkcredentials/circuits/build && shasum -a 256 -c SHA256SUMS
mkdir -p jpki_age_region_js && mv jpki_age_region.wasm jpki_age_region_js/
```
The dummy keys are test-only, but keep them off git (`circuits/build/` is ignored).

## 6. iPhone [local]
- Settings → Privacy & Security → **Developer Mode** on (appears after the first Xcode run).
- Xcode → Settings → Accounts: add your Apple ID; select your team for signing.
- NFC with ISO 7816 cards needs the *NFC Tag Reading* capability and the card AIDs in `Info.plist`
  (see `docs/research/ios-plan.md`). Whether a free personal team can use it is unverified — the paid Apple Developer Program
  is needed anyway for TestFlight.
