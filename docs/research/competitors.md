# Free alternatives and how p!pon differs (checked 2026-10-07)

Facts with sources; inferences are marked.

## Which ID people in Japan hold
- **My Number Card**: 104,536,420 held at end of Sep 2026, 84.5% of the population (MIC; `market-numbers.md`).
- **Passport**: 22,817,001 valid passports at end of 2025, about **17.8%** of Japanese nationals (123.192M, 2025-09-01);
  16.8% a year earlier. MOFA passport statistics as reported by
  [Travel Voice 2026-02-24](https://www.travelvoice.jp/20260224-159307) and
  [Nikkei](https://www.nikkei.com/article/DGXZQOUA200FA0Q5A220C2000000/) ("6 人に 1 人"). Primary tables:
  [MOFA 旅券統計](https://www.mofa.go.jp/mofaj/toko/passport/index.html).

## Free / open zero-knowledge ID tools
| Tool | Documents (as published) | Japan / My Number Card |
|---|---|---|
| **Self** (self.xyz) | Biometric passports of 127 nations, biometric national ID cards of 35 countries (list not published in the post), India's Aadhaar ([Self blog 2025-09-25](https://self.xyz/blog/self-now-supports-indian-aadhaar-expanding-support-to-99-of-india-s-adult-population); EU ID cards: [Biometric Update](https://www.biometricupdate.com/202509/self-integrates-aadhaar-to-enable-age-identity-verification-with-zkps)) | Not mentioned |
| **ZKPassport** (now part of Aztec Labs) | Passports and ID cards, "over 130 countries and regions" ([ethereum.org listing](https://ethereum.org/ja/apps/zk-passport)) | Not mentioned |
| **Anon Aadhaar** | India's Aadhaar only | No |

Open-source JPKI readers exist (e.g. [soltia48/myna-card](https://github.com/soltia48/myna-card), [github.com/jpki](https://github.com/jpki)),
but a search found **no zero-knowledge project for the My Number Card** (not proof of absence).

Inferences (to confirm before quoting as fact):
- Passport-style tools read the ICAO 9303 travel-document application; the My Number Card's signed data is in the
  separate JPKI application (`JPKIAPDU.aid`), so those tools would need new work (CA handling, certificate parsing,
  Japanese address) to support it.
- Passport data pages carry no address, so passport-based proofs cannot show residence (prefecture, city);
  the JPKI signing certificate carries the full address.

## Where the lasting difference is
1. **Entry**: the ID 84.5% of Japan holds, versus a passport held by about 1 in 6.
2. **Content**: residence facts (prefecture, later city), which passport tools cannot prove.
3. **Japan regulation and enterprise adoption**: the April 2027 IC-chip KYC rules, the J-LIS certified-operator path
   for revocation, Japanese support, SDK and legal documentation for buyers — work open-source projects rarely take on.
4. Abroad (ePassports, roadmap) p!pon meets these tools on the same standard; there the pitch is the shared Solana
   registry and reusable attestations.
