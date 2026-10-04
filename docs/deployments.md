# デプロイ記録

## devnet（2026-10-04）
| 項目 | 値 |
|---|---|
| Program `zk_gate` | [`AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK`](https://explorer.solana.com/address/AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK?cluster=devnet) |
| Upgrade authority | `7LQSbKRwxW7argJ4mUcLyRsPvq8yuzfzvxVr8aightAR`（`~/.config/solana/zkcred-devnet.json`、リポジトリ外） |
| Gate (scope=1, 20歳以上, 東京都) | `F8QEE9cre8L1b3c51jH7S6YhbLk8PQpCb4uQruxwrZF1` |
| 最初の claim | [tx](https://explorer.solana.com/tx/3LXGmNw29yR1oXRJEQrhtztvhru3i24CRaEAhRDV7QT2KcAq7kukWsosqf1A9D9DEman63Pw6t2bxxbPVLhf8uBz?cluster=devnet) / [asset](https://explorer.solana.com/address/D5bdYoccxc6ncooQLxG3uVoVFyDx9qjkg6p76XCXezHT?cluster=devnet)（143,945 CU） |

注意:
- scope=1 のゲートは **ダミーCA**（`circuits/build/dummy-ca.pem`、非コミット）だけを信頼する。この鍵を失うと scope=1 では新しい証明を作れない → 新しい scope でゲートを作り直す。
- 本番相当のゲートは J-LIS 署名用CA（signca02/03）の caKeyHash で作る（`docs/research/rsa-spike.md`）。
- 再デモ: `circuits/scripts/make-claim.sh <wallet> out.json` → `cd sdk && WALLET_KEYPAIR=... CLAIM=out.json npm run demo:devnet`
