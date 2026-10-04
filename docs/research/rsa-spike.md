# Spike: JPKI age + prefecture + nullifier circuit

Date: 2026-10-04 · Circuit: `circuits/src/jpki_age_region.circom` · Reproduce: `cd circuits && npm i && scripts/build.sh`

## Result
- **End to end with a dummy JPKI certificate: circuit → Groth16 proof → verification.** All 10 tampering tests are rejected.
- **1.49M constraints** (maxTbs = 2048 B). On a laptop (i7-10750H): rapidsnark **4.6 s**, snarkjs 31 s.
- **Main cost: a 928 MB zkey** to ship to phones. Measuring the real TBS size and lowering maxTbs is the first lever.

## What the circuit proves
| # | Statement | Building blocks |
|---|---|---|
| 1 | The TBSCertificate is signed by the CA key (SHA-256 + RSA-2048 PKCS#1 v1.5) | zk-email `Sha256Bytes`, `RSAVerifier65537` |
| 2 | Extracts the holder's public key from the TBS (SPKI header and exponent checked) | `VarShiftLeft` |
| 3 | Date of birth (SAN OID `.5.5.4`): `dob + age × 10000 ≤ currentDate` | |
| 4 | The address (SAN OID `.5.5.5`) starts with the name of `prefectureCode` (UTF-8, 47-entry table); short and long DER lengths | `gen/prefectures.circom` |
| 5 | The holder's key signed `chalMsg` (= SHA-256(wallet ‖ nonce)): possession of the card | second RSA |
| 6 | Outputs `caKeyHash = Poseidon(CA key)` and `nullifier = Poseidon(Poseidon(CA signature), scope)` | |

Public signals: `caKeyHash, nullifier` (outputs) + `chalMsg[2], currentDate, ageThreshold, prefectureCode, scope` = 8.

## Measurements (i7-10750H, 6C/12T, 16 GB)
| Item | Value |
|---|---|
| Non-linear constraints | 1,485,099 (maxTbs 2048) / 1,215,339 (1536) / 942,500 (1024) |
| Per 512 B of TBS | ≈ 270k constraints (8 SHA-256 blocks + selectors) |
| Fixed part (2 × RSA, challenge SHA, …) | ≈ 400k constraints |
| ptau | 2^21 (PSE Perpetual Powers of Tau `ppot_0080_21`) |
| circom compile | 54 s |
| Witness (wasm / node) | 7.1 s |
| Witness (native, rust-witness) | 3.5 s, 354 MB peak |
| Groth16 setup + contribution | 500 s + 157 s |
| **Prove, rapidsnark** | **4.6–6.0 s, 1.28 GB peak** |
| Prove, snarkjs | 31.3 s |
| Verify, snarkjs | 0.37 s |
| zkey / r1cs / wasm | 928 MB / 384 MB / 9.4 MB |
| Peak memory (setup) | 9.6 GB |

## Tests (`node test/witness.test.cjs`)
Accepted: valid input, long-form (132 B) address.
Rejected: other prefecture, out-of-range code, under age, date before the 20th birthday, one tampered TBS byte,
challenge for another wallet, DOB offset pointed at the address, shifted public-key offset, field outside the hashed data.

## Assumptions to confirm on a real card
- The dummy TBS is 707 B. Real signing certificates carry more extensions (CRL distribution points, policies, issuer
  alternative name), so **the real size is unknown**; maxTbs = 2048 is a safe placeholder.
- `EYYYYMMDD`: the year is assumed Gregorian (check the profile specification).
- The address is assumed to be a UTF8String; the `0x82` long form (> 255 bytes) is not handled.
- The card's challenge signature is assumed PKCS#1 v1.5 with a SHA-256 DigestInfo (consistent with myna-card's `Sha256DigestInfo`).
- `notBefore` ("issued within N days") is not implemented yet.

## Solana verification (`programs/zk_gate`)
- `initialize_gate(scope, min_age, allowed_prefectures (bitmask), ca_key_hashes, name, uri)` / `claim(proof)`.
- `claim` rebuilds the public inputs itself (`chalMsg = SHA-256(claimer ‖ nonce)`, `min_age` and `scope` from the gate,
  the date from the Clock in JST, today or yesterday only) → proofs cannot be reused by another wallet, with another age
  threshold or prefecture, or at another gate.
- The nullifier PDA `["nullifier", gate, nullifier]` is created with `init` → a second claim by the same person fails.
- A Metaplex Core asset is minted to the claimer (gate PDA as update authority).
- **Compute: 145,205 CU** in LiteSVM, 143,945 CU on devnet (Groth16 verify + PDA + mint), within the default 200k.
- Tests: `anchor build && scripts/fetch-programs.sh && cargo test -p zk_gate` (7: valid + replay, other wallet,
  disallowed prefecture, lying about the prefecture, untrusted CA, stale date, other scope).
- `caKeyHash` of the J-LIS signing CAs (`node circuits/scripts/export_solana.cjs cahash circuits/fixtures/jlis/*.cer`):
  - signca02: `0x0f8b63a80a1d2072363fd99ae06672d403b8ea2506aefba46c1076edd32f2e93`
  - signca03: `0x019d96eda27d0ab684f26405ef59ff856afd20fe36b9932a8a28434e6e55dfb8`

## Next
1. **Smaller zkey**: measure the real TBS and minimise maxTbs (1024 → ≈ 0.94M constraints, zkey ≈ 600 MB expected).
2. **On-device proving**: mopro with rust-witness + rapidsnark on the iPhone (`docs/research/ios-plan.md`).
3. Alternative only if needed: Noir/UltraHonk (no trusted setup, smaller keys) — on-chain verification cost is the open question.
