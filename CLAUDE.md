# zkCredentials — Solana Colosseum Hackathon

## 一行定義
政府発行ICチップ（マイナンバーカード等）の暗号学的真正性を Root of Trust とし、
個人情報を渡さずに「必要な事実だけ」を証明する Web2/Web3 共通の ZK クレデンシャル。

## コアメッセージ
- IC chips solve authenticity. Zero-knowledge credentials solve privacy.
- Why Now: 2027年4月、犯収法の非対面本人確認が画像送信型からICチップ読取型へ移行。

## 確定している方針
- **ポジショニング**: 法定KYCの置き換えではない。法的義務がないのに身分証を過剰収集している場面
  （年齢確認、一人一枠、Sybil耐性、イベント、メタバース、AI Agent委任）が主戦場。
- **Issuerなし（クライアント側証明）**: 端末でICチップを読み、発行者署名の検証をZK回路内で行い、
  属性（例: age>=20, unique_human）だけを出力する。Anon Aadhaar / Self 型。
- **個人番号（マイナンバー）は一切扱わない。**
- **Why Solana**: Nullifierレジストリ（サービス横断の一人一回）、alt_bn128によるオンチェーンGroth16検証、
  Solana Attestation Service との接続、Agent決済（x402等）との統合。

## 未決定（決めたら docs/decisions/ にADRを書き、ここを更新）
- MVPユースケース: (A) 年齢/固有性証明→ゲート付きミント (B) 検証済み人間によるAI Agent委任
- ZKスタック: Circom+Groth16（groth16-solana）暫定。Noir等と比較が必要なら spike で判断
- 証明元: JPKI署名用証明書 / 券面事項入力補助AP / 運転免許証IC — 署名の有無・PIN・民間利用条件を要確認
- 失効確認の扱い（J-LIS問い合わせは認定が必要。暫定は「発行後N日以内の証明のみ有効」）
- モバイル: Expo/React Native + NFC 暫定
- ハッカソン提出期限: 2026-10-21。**プロダクト完成目標は 2026-10-16**（残りはピッチ動画等に充てる）

## リポジトリ構成
- circuits/   ZK回路（src, test, fixtures）
- programs/   Solanaプログラム（Anchor）
- app/mobile/ iPhone用アプリ（NFC読取・プルーフ生成）
- app/verifier-demo/ 検証側デモ（Web2サイト想定）
- sdk/        検証者向けSDK
- docs/decisions/ ADR（意思決定記録）
- docs/research/  競合・技術調査
- docs/pitch/     ピッチ素材
- docs/legal/     犯収法・JPKI関連の一次資料メモ
- inbox/      iPhoneから送った写真・PDFの置き場（処理後に適切な場所へ移す）

## 作業ルール（リモート操作前提）
- **報告はスマホで読める短さに**: 結論→変更点→次の判断事項、の順で数行。長い出力はファイルに書いてパスを示す。
- **判断が必要なときは選択肢を2〜3個に絞って質問する。** 勝手に大きな方針転換をしない。
- **小さくコミット**: 意味のある単位で commit し、メッセージは日本語可・具体的に。
- **長い処理（ビルド、セットアップ、ベンチマーク）が終わったら通知する。**
- **sudo が必要な操作は実行せず、コマンドを提示して止まる**（リモートからはパスワード入力できない）。
- **実在の個人情報をリポジトリやテストに入れない。** テストは自前で生成したダミー証明書・鍵を使う。
- 秘密鍵・.env・Solanaキーペアは読まない、コミットしない。
- 規制や仕様に関する主張は docs/legal/ に一次資料URL付きで記録し、推測と事実を分ける。
