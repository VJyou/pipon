# Root of trust: JPKI / card-face text AP / driver's licence IC / iPhone

Researched 2026-10-04. Legend: **[Fact]** checked against a primary source · **[Secondary]** OSS or vendor articles (primary
source not yet checked) · **[Inference]** our reading, needs expert confirmation.
Japanese names of laws and documents are kept in parentheses so they can be looked up.

## Conclusion

| Use | Source | Why |
|---|---|---|
| Age (≥ 20) and region | **JPKI signing certificate** (署名用電子証明書) | Best primary documentation (public CA certificate and CPS); never touches the Individual Number |
| Uniqueness only | **JPKI user-authentication certificate** (利用者証明用電子証明書) | No attributes, 4-digit PIN; best UX |
| Backup | Card-face text AP (券面事項入力補助AP) | 4-digit PIN gives the date of birth, but the CA key is unpublished and the signed record contains a hash of the Individual Number |
| Out of scope (MVP) | Driver's licence IC | Signed data includes registered domicile and photo, needs PIN1 + PIN2, public-key distribution unknown |

**Design requirement for every source**: a certificate is not secret (it can be copied), so knowing it proves nothing.
The circuit must verify **a signature by the card's private key over a challenge** (PIN/password required) bound to the
wallet or session → at least two RSA-2048 verifications in the circuit (CA → certificate, certificate → challenge).

---

## 1. JPKI (public-key authentication application)

- **[Fact]** The signing certificate records the four basic attributes (name, address, date of birth, sex) and is issued
  to holders aged 15+. The user-authentication certificate records none of them.
  — Guidelines for private businesses using JPKI, v1.6 (公的個人認証サービス利用のための民間事業者向けガイドライン 第1.6版, Oct 2025)
  https://www.digital.go.jp/assets/contents/node/basic_page/field_ref_resources/1f2fb150-febe-4bee-b691-f02f68c4e8d4/3d68c090/20251010_policies_mynumber_private-business_outline_01.pdf
- **[Fact]** Keys: the signing CA and holders use **RSA 2048-bit** (CPS 6.1.5).
  — Signing CA Certification Practice Statement v3.3 (署名用認証局 運用規程, 2026-05-26) https://www.jpki.go.jp/ca/pdf/sign_cps.pdf
- **[Fact]** The signing CA's self-signed certificates are public (CPS 2.2). Downloaded and checked on 2026-10-04 with openssl:

  | File | Validity | SHA-256 fingerprint |
  |---|---|---|
  | signca01.cer | 2015-10-20 – 2025-10-19 (expired) | 19:64:54:05:…:FC:93:55 |
  | signca02.cer | 2019-09-14 – 2029-09-14 | 79:67:9C:33:…:E6:FB:EB |
  | signca03.cer | 2023-07-16 – 2033-07-15 | D2:27:F6:CD:…:FA:36:5F |

  All RSA-2048, e = 65537, sha256WithRSAEncryption. Source: https://www.jpki.go.jp/ca/ca_rules3.html.
  All three fingerprints match J-LIS's published list (https://www.jpki.go.jp/ca/pdf/sign_fingerprint.pdf).
  Stored in `circuits/fixtures/jlis/` (public data).
- **[Fact]** Validity of a signing certificate: until the holder's 5th birthday after issuance, or earlier if the card or
  the authentication certificate expires first; smartphone certificates follow the card's (CPS 6.3.2.2).
  → reading `notBefore` in the circuit allows an "issued within N days" policy.
- **[Fact]** Revocation reasons: expiry; loss/theft of the card or phone; and, for the signing certificate only, a change of
  name or address (Guidelines ch. 2 (2) イ).
- **[Fact]** A private business needs ministerial certification under Art. 17(1)(vi) of the JPKI Act to obtain
  **revocation information** (Guidelines ch. 4 (2)). Certified verifiers must not use holders' public keys or revocation
  data for other purposes (Table 4-1).
- **[Fact]** CPS 2.2: revocation information for signing certificates is provided only to signature verifiers as defined by law.
- **[Secondary]** Reading the signing certificate requires the signing password (6–16 alphanumerics). The authentication
  certificate is readable without a PIN; signing with it needs the 4-digit PIN.
  — https://tex2e.github.io/blog/crypto/my-number-card , https://github.com/soltia48/myna-card
- **[Secondary]** The attributes are subjectAltName OtherName values, OID 1.2.392.200149.8.5.5.{1 name, 3 sex,
  4 date of birth `EYYYYMMDD` (E = era), 5 address}. Primary source: J-LIS certificate profile v3.2
  (公的個人認証サービス プロファイル仕様書) https://www.j-lis.go.jp/file/13_profile_genkou.pdf (blocked for scripted download; check manually).
- **[Secondary]** AID of the JPKI application: `D3 92 F0 00 26 01 00 00 00 01` (must be listed for iOS Core NFC).

### Legal questions (JPKI)
- **[Inference]** Certification is required to *obtain revocation information*. Verifying the CA signature on the device
  without revocation data reads as outside that requirement, **but we have not found an explicit basis**. To confirm with
  the Digital Agency / Ministry of Internal Affairs or counsel. In the pitch: revocation checks later via a certified
  platform operator (プラットフォーム事業者特例).
- **[Inference]** Without revocation, a lost card or one whose holder has moved can still produce proofs. An "issued within
  N days" policy does not catch revocations inside the (up to 5-year) validity; we state this limit.

## 2. Card-face text AP (券面事項入力補助AP)

- **[Secondary]** Read with the 4-digit PIN; AID `D3 92 10 00 31 00 01 01 04 08`. Files (per the myna-card implementation):
  - `0001` Individual Number / `0002` four attributes / `0003` integrity record / `0004` card-verifiable certificate (not X.509) /
    `0007` card key + issuer signature
  - `0003` = `DF31: SHA-256(Individual Number file)` + `DF32: SHA-256(attributes file)` + `DF33: RSA-2048 signature`
  - Check code B (date of birth + expiry year + security code) opens `0002`/`0003` but not `0001`
  — https://github.com/soltia48/myna-card (based on reverse engineering)
- **[Secondary]** The issuer CA key (`5000033`) is not inside the CVC and **we could not find it published by J-LIS**.
- **[Inference]** The attributes can be verified without reading the Individual Number itself, but `0003` contains a
  **SHA-256 of the Individual Number file (12 digits, so brute-forceable)**. Whether that is a "code used in place of the
  Individual Number" under the My Number Act Art. 2(8) is unclear → conflicts with our rule of never handling the
  Individual Number; not used.

## 3. Driver's licence IC

- **[Fact]** Specification v10 (National Police Agency notice 丁運発第145号, 2024-07-19)
  https://www.npa.go.jp/laws/notification/koutuu/menkyo/menkyo20240719_145.pdf
  - Signature: SHA-256(DF1/EF01 (880 B) ‖ DF1/EF02 (82 B, registered domicile) ‖ DF2/EF01 (2005 B, photo)), RSA-2048
    PKCS#1 v1.5 (section 4); the drawn padding is `00 01 FF…FF 00 ‖ hash`, **without DigestInfo**.
  - Reading: DF1/EF01 needs PIN1; DF1/EF02 and DF2/EF01 need **PIN1 and PIN2**; PINs cannot be changed, 3 tries.
  - EF07 carries issuer name and subject key id; **public-key distribution is not described**.
- **[Inference]** ~3 KB to hash (≈47 SHA-256 blocks) and two PINs: not suitable for the MVP.

## 4. My Number Card on iPhone (Apple Wallet / smartphone certificate)

- **[Fact]** The AML/CFT rules (犯収法施行規則) add identification by the smartphone-embedded card record
  (new Art. 6(1)(i)(ル)), promulgated 2025-06-24; authenticity via signatures by J-LIS and the holder's phone.
  — Q&A https://www.npa.go.jp/sosikihanzai/jafic/hourei/data/25062401qa.pdf
- **[Secondary / Apple]** The Wallet card is an ISO 18013-5 mdoc; the Verify with Wallet API returns Age Over N etc.
  Verifiers need **Apple entitlement approval and certification under Japanese law**. J-LIS publishes the IACA certificate
  (https://www.j-lis.go.jp/pn/mdociaca.html). — https://developer.apple.com/wallet/get-started-with-verify-with-wallet/
- **[Inference]** Third-party apps cannot read Wallet data on device to build a ZK proof → not usable for client-side
  proving. Apple already offers "age only" disclosure, so we differentiate on **cross-service one-per-person
  (nullifiers), on-chain verification, and no Apple approval or government certification for verifiers**.

## 5. April 2027 AML/CFT change (the "why now")

- **[Fact]** Amendment promulgated 2025-06-24 abolishing high-impersonation-risk methods. The Q&A confirms the end of the
  photo-upload method and requires, for IC-chip methods, confirming authenticity of the chip data "by decrypting with the
  public key the chip data encrypted with the private key" (Q6).
  — https://www.npa.go.jp/sosikihanzai/jafic/hourei/data/25062402qa.pdf
- **[Secondary]** Effective 2027-04-01. — https://www.primagest.co.jp/column/hanshuho-2027-kaisei/ (confirm in the Official Gazette)

## 6. Future risk

- **[Secondary]** The next-generation card (target FY2028) is expected to move from RSA to ECDSA and extend certificate
  validity to 10 years. — Digital Agency task force material
  https://www.digital.go.jp/assets/contents/node/basic_page/field_ref_resources/c6296242-c198-4fcd-8a17-b6168f9f5fa1/56bcc279/20231121_meeting_mynumber-card-renewal_outline_04.pdf
  → the circuit targets current RSA-2048 cards; ECDSA support is future work.

## TODO
- [ ] Fetch profile v3.2 in a browser; confirm SAN OIDs and certificate size from the primary source
- [ ] Ask the Digital Agency / MIC about on-device verification without revocation data (can be after the hackathon)
- [ ] Measure the real signing certificate's DER size and SAN layout (record sizes only; never commit the certificate)
