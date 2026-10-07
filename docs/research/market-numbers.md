# Numbers for the pitch (checked 2026-10-07)

Facts with sources; inferences are marked as such.

## My Number Card
- **104,536,420 cards held** at the end of September 2026, **84.5%** of the population (123,767,642 as of
  2026-01-01). "Held" = issued minus cards cancelled (death, expiry, etc.).
  Source: Ministry of Internal Affairs and Communications (総務省), マイナンバーカード交付状況, R8.9末 data:
  [page](https://www.soumu.go.jp/kojinbango_card/kofujokyo.html),
  [xlsx](https://www.soumu.go.jp/main_content/001095358.xlsx), [pdf](https://www.soumu.go.jp/main_content/001095357.pdf).
- Inference, not checked: not every card carries a valid **signing certificate** (it is optional at issuance and
  expires after five years, while the card lasts ten for adults), so the number of cards that can produce a proof
  today is lower than the number held. Find a J-LIS figure for signing certificates before quoting one.
  Pitch wording: "over 100 million cards", not "100 million signing certificates".

## Personal data leaks in Japan
- **FY2024: 19,056** personal-data breach reports processed by the Personal Information Protection Commission (PPC)
  under Art. 26(1) of the APPI (14,198 direct, 4,858 via delegated ministries) — a record high.
  Source: [PPC annual report FY2024 (令和6年度年次報告)](https://www.ppc.go.jp/aboutus/report/annual_report_2024/).
- **2025: listed companies and their subsidiaries announced 180 leak/loss incidents, 30,636,910 people affected**
  (+93.1% year on year), 158 companies (a record). Causes: malware / unauthorised access 64.4%, mis-display /
  mis-sending 20.5%, loss / disposal 10.0%. Largest: AOKI HD ~7.29M, SOMPO HD ~7.27M, Asahi Group HD ~1.91M.
  Source: [Tokyo Shoko Research, 2026-01-30](https://www.tsr-net.co.jp/data/detail/1202348_1527.html).
- Inference: these incidents are not all ID-document leaks; the claim the pitch can support is "personal data
  leaks at record scale", and that **data that is never collected cannot leak**.

## Times Car breach (September–October 2026)
- Park24 detected unauthorised access to the Times Car (car-sharing) website on **2026-09-25 09:07** and cut the
  route by 2026-09-26 07:25 ([1st report](https://www.park24.co.jp/news/2026/09/web1.html)).
- **About 6.6 million** member and former-member accounts; data: name, address, date of birth, phone, email, member
  number, licence information, ID-document images, corporate member data, linked service IDs. **About 1.6 million**
  accounts had **ID-document images** (driver's licences, student cards, etc.). No credit card data confirmed.
  ([2nd report, 2026-09-28](https://www.park24.co.jp/news/2026/09/20260928-1.html),
  [3rd report, 2026-09-29](https://www.park24.co.jp/news/2026/09/20260929-1.html);
  [Nikkei](https://www.nikkei.com/article/DGXZQOUC284OR0Y6A920C2000000/))
- Public safety commissions (e.g. Kansai) are reissuing driver's licences for affected people
  ([NHK, 2026-10-06](https://news.web.nhk/newsweb/na/nd-20261006de55511)). Police received about 190 consultations on
  2026-09-30–10-01 ([piyolog summary](https://piyolog.hatenadiary.jp/entry/2026/09/28/214857)).
- Inference: a car-sharing service must check the driving licence itself, which zkCredentials (My Number Card
  attributes) does not prove today. The pitch uses the breach as evidence that **stored ID images leak**, not as a
  case zkCredentials would have solved directly. Do not name or show Park24 / Times branding in the video.
