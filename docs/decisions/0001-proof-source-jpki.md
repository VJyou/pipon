# ADR-0001: Use JPKI as the root of trust

- Date: 2026-10-04
- Status: Accepted

## Context
The client-side ZK proof needs an IC-chip data source as its root of trust. Research: `docs/legal/proof-sources.md`.

## Options
1. JPKI signing / user-authentication certificates
2. Card-face text AP (券面事項入力補助AP)
3. Driver's licence IC

## Decision
Use JPKI.
- Attributes (age, region) → **signing certificate** (6–16 character password)
- Uniqueness only → **user-authentication certificate** (4-digit PIN)
- In both cases the circuit verifies a signature by the card's private key over a challenge bound to the wallet or session.

## Consequences
- Primary documentation is available (CPS, published CA certificates) and the Individual Number is never touched.
- The card-face AP signs a record that includes a hash of the Individual Number and its CA key is unpublished; the
  driver's licence signs a large blob including domicile and photo, needs two PINs and has no documented key distribution.
- Trade-offs: the signing password is heavier UX (locks after 5 wrong tries). Revocation data needs government
  certification, so revocation is not checked for now.
- The next-generation card (target FY2028) is expected to move to ECDSA → a second circuit will be needed later.
