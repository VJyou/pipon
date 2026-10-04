# iPhoneから最初に送る指示（コピペ用）

## 1. ツールチェーン導入
CLAUDE.md を読んで。暫定スタック（Rust, Solana CLI, Anchor, Node LTS, circom, snarkjs）の導入状況を確認し、
未導入のものを公式ドキュメントの最新手順で入れて。sudoが要るものはコマンドだけ示して止まって。
終わったらバージョン一覧を docs/toolchain.md に書いて通知して。

## 2. 技術リスクの spike（最優先）
RSA-2048 署名検証 + SHA-256 を含む Circom 回路の制約数とプルーフ生成時間を見積もるspikeを
circuits/ に作って。既存実装（Anon Aadhaar, zk-email の RSA 回路など）を参考に、
ダミー鍵で検証まで通し、結果を docs/research/rsa-spike.md にまとめて。

## 3. 競合調査
Self Protocol, zkPassport, Anon Aadhaar, Civic, Solana Attestation Service を比較して
docs/research/competitors.md にまとめて。差別化ポイントの仮説も3つ書いて。

## 4. Solana側の土台
programs/ に Anchor プロジェクトを作り、groth16-solana で固定の検証鍵のプルーフを検証し、
nullifier を PDA に記録して二重使用を拒否する最小プログラムとテストを書いて。
