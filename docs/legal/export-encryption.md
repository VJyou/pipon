# Export compliance (encryption) for the iPhone app

Checked 2026-10-08, for TestFlight and later the App Store. Not legal advice; confirm with counsel before an App Store
release.

## Facts (primary sources)

1. **Apple: uploading is an export.** "When you submit your app to TestFlight or the App Store, you upload your app to a
   server in the United States. If you distribute your app outside the U.S. or Canada, your app is subject to U.S.
   export laws, regardless of where your legal entity is based." "If your app uses, accesses, contains, implements, or
   incorporates encryption, this is considered an export of encryption software."
   — https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
2. **Apple: `ITSAppUsesNonExemptEncryption`.** "Set the value to NO if your app—including any third-party libraries it
   links against—doesn't use encryption, or if it only uses forms of encryption that are exempt from export compliance
   documentation requirements." "Typically, the use of encryption that's built into the operating system—for example,
   when your app makes HTTPS connections using URLSession—is exempt from export documentation upload requirements,
   whereas the use of proprietary encryption is not."
   — same page; https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption
3. **Apple: possible year-end report.** "If your app uses exempt forms of encryption, you might alternatively be required
   to submit a year-end self-classification report to the U.S. government." — same page.
4. **BIS: functions outside 5A002.a.** 'Cryptography for data confidentiality' excludes cryptography limited to:
   authentication; digital signature; data integrity; non-repudiation; digital rights management; encryption or
   decryption for entertainment, mass commercial broadcasts or medical records management; and key management for
   these. "The use of cryptography limited to a-g listed above, results in a classification of the product NOT in
   5A002.a. In that case, you should review other entries in Category 5 Part 2 and other Categories on the CCL (e.g.,
   Cat. 4 or Cat. 5, Part 1). If it is not described in any other Category then it can be classified as EAR99."
   — https://www.bis.gov/learn-support/encryption-controls/cryptography-for-data-confidentiality

## What the app does with cryptography (from the code, 2026-10-08)

| Use | Where | Function |
|---|---|---|
| HTTPS to the demo site | `URLSession` (OS) | OS-provided encryption in transit |
| SHA-256 of the session binding and nonce | `ZkCredCore/CircuitInput.swift` (swift-crypto) | Data integrity |
| RSA PKCS#1 v1.5 signature verification of the card's challenge and of the CA's signature on the certificate | `ZkCredCore/TrustAnchors.swift` (swift-crypto `_RSA`) | Authentication / digital signature |
| RSA signing with the demo card's TEST key | `ZkCredCore/DevCard.swift` | Digital signature |
| Card signs the challenge (on the chip) | `JPKIReader.swift`, plain APDUs over Core NFC | Digital signature (done by the card) |
| Groth16 zero-knowledge proof | mopro / rapidsnark (Rust, C++) | Proves facts about signed data; no encryption of data |

No code path encrypts or decrypts data for confidentiality (no AES, ChaCha, sealed boxes or key exchange in the app's
code). Search: `grep -rnE 'AES|ChaCha|SealedBox|Cipher|Encrypt' app/mobile --include='*.swift'` finds nothing outside build output
and the generated mopro bindings.

## Inference

- The app's own cryptography is limited to authentication, digital signature and data integrity (fact 4), and its
  only confidentiality encryption is the OS's HTTPS (fact 2). So it qualifies for `ITSAppUsesNonExemptEncryption = NO`.
- Under fact 4 the app's own cryptography falls outside 5A002.a, which would make it EAR99 and need no year-end
  self-classification report (fact 3 applies to exempt *encryption* such as mass-market items). This is our reading,
  not a ruling.

## Open points

- swift-crypto (BoringSSL inside) also contains AES and other ciphers that the app never calls. Classification follows
  what the item does, but this is the weakest point of the argument; removing unused code is not practical.
- France has its own declaration rules for encryption; Apple's questionnaire asks about distribution there. Not checked
  yet; for TestFlight, check what App Store Connect asks.
- Confirm with counsel before the App Store (not TestFlight) release.

## Decision

- TestFlight build: answer that the app uses only exempt encryption; set `ITSAppUsesNonExemptEncryption = NO` in the
  build settings. [pending the owner's go]
