# RSA spike: JPKI 年齢＋都道府県＋nullifier 回路

日付: 2026-10-04 / 回路: `circuits/src/jpki_age_region.circom` / 再現: `cd circuits && npm i && scripts/build.sh`

## 結論
- **ダミーJPKI証明書で end-to-end（回路→Groth16証明→検証）が通った。** 改ざん系の否定テスト10件もすべて期待どおり拒否。
- 制約数 **1.49M**（maxTbs=2048B）。PC（i7-10750H）で rapidsnark **4.6秒**、snarkjs 31秒。
- **最大の課題は zkey 928MB**（モバイルへの配布）。実カードの TBS サイズを測って maxTbs を下げるのが最優先。

## 回路が証明すること
| # | 内容 | 主な部品 |
|---|---|---|
| 1 | TBSCertificate が CA 鍵で署名されている（SHA-256 + RSA-2048 PKCS#1 v1.5） | zk-email `Sha256Bytes`, `RSAVerifier65537` |
| 2 | TBS 内の利用者公開鍵（SPKIヘッダ/指数を照合して抽出） | `VarShiftLeft` |
| 3 | SAN OID `.5.5.4` の生年月日 → `dob + 年齢×10000 <= currentDate` | |
| 4 | SAN OID `.5.5.5` の住所先頭が `prefectureCode` の都道府県名（UTF-8, 47件表）。DER短/長形式両対応 | `gen/prefectures.circom` |
| 5 | 利用者鍵が `chalMsg`（=SHA256(wallet‖nonce) を想定）に署名（カードの所持証明） | RSA 2回目 |
| 6 | 出力 `caKeyHash = Poseidon(CA鍵)`、`nullifier = Poseidon(Poseidon(CA署名), scope)` | |

公開入力: `chalMsg[2], currentDate, ageThreshold, prefectureCode, scope`（+出力2）= 8 個。

## 計測（i7-10750H 6C/12T, 16GB RAM）
| 項目 | 値 |
|---|---|
| 非線形制約 | 1,485,099（maxTbs=2048） / 1,215,339（1536） / 942,500（1024） |
| TBS 512B あたり | 約 27万制約（SHA-256 8ブロック＋選択回路） |
| 固定部分（RSA×2・チャレンジSHA等）の目安 | 約 40万制約 |
| ptau | 2^21（PSE Perpetual Powers of Tau `ppot_0080_21`） |
| circom コンパイル | 54 s |
| witness 生成（wasm/node） | 7.1 s |
| groth16 setup + contribute | 500 s + 157 s |
| **証明 rapidsnark** | **4.6 s** |
| 証明 snarkjs | 31.3 s |
| 検証 snarkjs | 0.37 s |
| zkey / r1cs / wasm | 928 MB / 384 MB / 9.4 MB |
| ピークメモリ（setup） | 9.6 GB |

## テスト（`node test/witness.test.cjs`）
受理: 正常入力、長形式（132B）住所。
拒否: 別の都道府県、範囲外コード、年齢不足、誕生日前の日付、TBS 1バイト改ざん、別ウォレットのチャレンジ、
DOB オフセットを住所に向ける、公開鍵オフセットずらし、ハッシュ範囲外のフィールド参照。

## 前提・未確認（実カードで要確認）
- ダミーの TBS は 707B。実 JPKI 署名用証明書は拡張（CRL配布点、ポリシー、発行者別名等）が多く**実サイズ不明** → maxTbs=2048 は安全側の仮置き。
- 生年月日 `EYYYYMMDD` の YYYY を**西暦と仮定**（プロファイル仕様書で要確認）。
- 住所の文字列型を UTF8String と仮定。0x82 長形式（256B超）は未対応。
- カードのチャレンジ署名が `DigestInfo(SHA-256)` 付き PKCS#1 v1.5 であること（myna-card の `Sha256DigestInfo` と整合）を実カードで確認。
- 証明書の `notBefore`（発行後N日以内ポリシー）は未実装。

## 次の打ち手（優先順）
1. **zkey サイズ削減**: 実 TBS を測り maxTbs を最小化（1024 なら約0.94M制約、zkey 約600MB見込み）。
2. **モバイル証明**: mopro / rapidsnark iOS で iPhone 実測。zkey はアプリ初回にダウンロード＋キャッシュ。
3. **Solana 検証**: groth16-solana で公開入力8個の検証 CU を計測、nullifier PDA。
4. 代替案（必要時のみ）: Noir/UltraHonk（trusted setup 不要・鍵小）だがオンチェーン検証コストが課題。
