# Crypto World's Fair Hackathon — rules check

Checked 2026-10-04 against https://colosseum.com/legal/Crypto%20World's%20Fair%20Hackathon%20Rules.pdf

## Deadline
- **Contest Period: 2026-09-14 6:00am PT – 2026-10-12 11:59pm PT (= 2026-10-13 15:59 JST)** (§5). Confirmed.
- Individual registration closes at the same time (§6(a)); the team leader uploads the Project Submission in time (§6(b)).

## Checklist

| Rule | Requirement | Status | Action |
|---|---|---|---|
| §3(a) | 18+ | — | — |
| §3(b) | Sanctions exclusions | Japan resident: not affected | — |
| §3(c) | Participation does not breach employer policies | To confirm | Check employer side-work / invention rules |
| §5/§6 | Deadline, registration | Deadline confirmed | Register on colosseum.com |
| §7 | One team, one submission | OK | — |
| §8 | Judging: functionality, impact, novelty, UX, **open source**, business plan | Repo private until submission | Publish with LICENSE before submitting |
| §9 | Disclose open-source / third-party code | `THIRD_PARTY_NOTICES.md` | Keep up to date |
| §12(a)(i) | **All Content must be in English** | README, docs, UI, commits in English; Japanese only as data (prefecture names, official document titles, dummy addresses) | Remove or translate internal notes before publishing |
| §12(b)(ii)(iv) | No infringement of rights / privacy; consent of people shown | Dummy data only | No real card or personal data in the video |
| §12(b)(viii) | Nothing unlawful | Demo uses a dummy CA and dummy certificates | Real-card use flagged as pending regulatory confirmation (`proof-sources.md`) |
| §17 | No Colosseum trademarks / logos without consent | Not used | Keep logos out of the pitch |
| §14(e) | Solana track: products integrating Solana | Running on devnet | Eligible |

## Dependency licences (input for §9 and the project licence)
| Dependency | Licence | Use |
|---|---|---|
| circomlib | GPL-3.0 | compiled into the circuit |
| snarkjs / circomlibjs | GPL-3.0 | proving, verification, hashing |
| @zk-email/circuits | MIT | compiled into the circuit |
| groth16-solana | MIT | on-chain verification |
| anchor-lang | Apache-2.0 | program framework |
| mpl-core | Metaplex NFT Open Source License v1.0 | mint CPI |

The circuit links circomlib (GPL-3.0), so the project is licensed **GPL-3.0**.
