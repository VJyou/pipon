# First instructions sent from the iPhone (copy-paste)

## 1. Toolchain
Read CLAUDE.md. Check the provisional stack (Rust, Solana CLI, Anchor, Node LTS, circom, snarkjs), install what is
missing following the latest official instructions, and stop with the commands if anything needs sudo.
When done, write the versions to docs/toolchain.md and notify me.

## 2. Technical-risk spike (top priority)
Build a spike in circuits/ that estimates the constraint count and proving time of a Circom circuit including
RSA-2048 signature verification + SHA-256. Use existing implementations (Anon Aadhaar, zk-email's RSA circuits) as
references, verify with dummy keys end to end, and summarise in docs/research/rsa-spike.md.

## 3. Competitive research
Compare Self Protocol, zkPassport, Anon Aadhaar, Civic and Solana Attestation Service in docs/research/competitors.md,
with three differentiation hypotheses.

## 4. Solana foundation
Create an Anchor project in programs/ with a minimal program and tests that verify a proof against a fixed verifying
key with groth16-solana and record the nullifier in a PDA to reject double use.
