# Crypto World's Fair Hackathon 公式ルール照合

確認日: 2026-10-04 / 一次資料: https://colosseum.com/legal/Crypto%20World's%20Fair%20Hackathon%20Rules.pdf

## 最重要: 期限
- **[事実] Contest Period: 2026-09-14 6:00am PT 〜 2026-10-12 11:59pm PT（= 日本時間 10/13(火) 15:59）**（§5）
- 個人登録も同じ期限まで（§6(a)）。チームリーダーが期限内に Project Submission をアップロード（§6(b)）。
- CLAUDE.md の「提出期限 10/21」と不一致 → **要確認**（サイト上の変更告知がない限りルールPDFが優先）。

## 照合結果

| 条項 | 内容 | 現状 | 対応 |
|---|---|---|---|
| §3(a) | 18歳以上 | 要本人確認 | — |
| §3(b) | 制裁対象国等の除外 | 日本在住なら該当なし | — |
| §3(c) | 雇用主の規程・契約に反しない | **未確認** | 勤務先の副業・発明規程を確認 |
| §5/§6 | 期限・登録 | **期限が想定より8日早い** | 計画を前倒し |
| §7 | 1人1チーム・1提出 | OK | — |
| §8 | 評価: 機能/インパクト/新規性/UX/**オープンソース**/事業計画 | リポジトリ非公開、LICENSE なし | 提出前に公開＋LICENSE |
| §9 | OSS・第三者コードの状況を運営に申告 | 未整理 | THIRD_PARTY ノティス作成 |
| §12(a)(i) | **All Content must be in English** | README は英語、docs/ADR/コミットの多くは日本語、UIは英語＋一部日本語 | 提出物（README、動画、デモ、主要docs）を英語化 |
| §12(b)(ii)(iv) | 他者の権利・プライバシー侵害禁止、映る人物の許諾 | ダミーデータのみ | 動画に実カード・実個人情報を映さない |
| §12(b)(viii) | 違法な内容の禁止 | デモはダミーCA/ダミー証明書 | 実カード利用は規制確認前として明記（docs/legal/proof-sources.md） |
| §17 | Colosseum の商標・ロゴ無断使用禁止 | 未使用 | ピッチにロゴを入れない |
| §14(e) | Solana track（Solana 統合プロダクト） | devnet で動作 | 対象 |

## 依存ライセンス（§9 申告・LICENSE 選定の材料）
| 依存 | ライセンス | 使い方 |
|---|---|---|
| circomlib | GPL-3.0 | 回路に組込み |
| snarkjs / circomlibjs | GPL-3.0 | 証明・検証・ハッシュ計算 |
| @zk-email/circuits | MIT | 回路に組込み |
| groth16-solana | MIT | オンチェーン検証 |
| anchor-lang | Apache-2.0（要確認） | プログラム |
| mpl-core | Metaplex NFT Open Source License v1.0 | ミントCPI |

[推測] 回路は circomlib（GPL-3.0）を取り込むため、回路部分を配布するなら GPL-3.0 互換が必要。
→ リポジトリ全体を **GPL-3.0** にするのが最も単純（Solana プログラム・SDK を別ライセンスにする場合は分割を検討）。
