# ADR-0002: MVP = age + prefecture + one-per-person → gated mint

- Date: 2026-10-04
- Status: Accepted

## Context
Candidates were (A) age / uniqueness proofs → gated mint and (B) delegation to AI agents by verified humans.
Apple Wallet's My Number Card already offers selective disclosure of age (Age Over N), so age alone differentiates poorly.

## Options
1. (A) Age only
2. (A') Age + prefecture + nullifier
3. (B) AI-agent delegation

## Decision
(A'). One proof from one signing certificate outputs `age ≥ 20`, the `prefecture code` and a per-service nullifier; on
Solana, Groth16 verification plus a nullifier PDA gate a one-per-person mint.

## Consequences
- Prefecture enables region-limited drops, local DAOs and municipal points — distinctly Japanese, and something Apple
  Wallet does not offer.
- At prefecture level the anonymity set is at least several hundred thousand people. Municipalities would shrink it too
  much, so they are out of the MVP.
- Without revocation, a certificate issued before a move can still prove the old address (up to 5 years). Mitigated by an
  "issued within N days" policy; the limit is stated.
- (B) is mentioned in the pitch as an extension.
