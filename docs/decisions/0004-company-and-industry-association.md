# ADR-0004: p!pon as a company; a separate industry association for the legal standing of ZK proofs

- Date: 2026-10-07
- Status: Accepted 2026-10-07 (legal and tax details still to be confirmed with a judicial scrivener / tax accountant)

## Context
- p!pon needs revenue and outside investment (verification fees, SDK, attestations; accelerator funding).
  A general incorporated association (一般社団法人) cannot issue shares or distribute profits, so it cannot be the
  operating company.
- Whether a zero-knowledge proof over a JPKI certificate is acceptable evidence under Japanese rules is open
  (e.g. on-device verification without revocation data, `docs/legal/proof-sources.md`). One company asking alone
  carries little weight; regulators respond better to an industry view.
- Similar projects (Ethereum-based ZK identity, accelerators, consultancies) face the same question.

## Options
1. Company only (株式会社).
2. Association only (一般社団法人).
3. Company for the product, plus a separate, vendor-neutral association co-founded with peers.

## Decision
Option 3.
- **p!pon (company)**: product, SDK, fees, investment. One member of the association, not its owner.
- **Association** (chain-neutral theme: "zero-knowledge identity and data minimisation"), with ZK/Ethereum projects,
  accelerators and consultancies: study sessions, guidelines, briefings for regulators (NPA/JAFIC and FSA for the AML
  rules; Digital Agency, MIC and J-LIS for the card and JPKI; the Personal Information Protection Commission),
  joint use of the grey-zone resolution system, and shared governance of trust lists and technical specs.

## Why it matters beyond p!pon (our thesis)
- **For people in Japan**: if a ZK proof is accepted as a lawful way to check age, residence or uniqueness, services
  no longer need to collect ID copies. Fewer copies mean fewer leaks for everyone, not only p!pon users. Speaking as
  one industry is how that acceptance becomes realistic.
- **For other countries**: Japan has a national PKI on 100M+ cards and moves remote KYC to the IC chip in April 2027.
  A clear legal status for ZK proofs here would be an early, concrete precedent that other regulators — and
  blockchain-based identity projects abroad — can point to, speeding up adoption elsewhere.
  (Thesis, not a fact; no regulator has yet ruled on ZK proofs over JPKI.)

## Guardrails
- Vendor neutrality: several companies on the board, no product endorsements, transparent governance.
- Competition law: no discussion of prices or customer allocation among members.
- Check overlap with existing bodies (JBA, JCBA, OpenID Foundation Japan, MyData Japan); a working group inside one
  of them may be faster than a new association.
- Sequencing: informal monthly study group first (to Dec 2026); incorporate when 3–5 committed members exist
  (Jan–Mar 2027); first output: a data-minimising age-check guideline for the April 2027 IC-chip shift.

## Consequences
- Pitch: one slide on ecosystem and policy.
- Founder time is split; product and fundraising keep priority until the association has members.
