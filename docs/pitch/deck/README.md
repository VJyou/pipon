# p!pon pitch deck

- `pipon-pitch.pdf` — the deck as a PDF (pitch, business overview, technical demo).
- `slides/*.html`, `deck.json` — the slide sources (one 1920×1080 `<section>` per file, order in `deck.json`; speaker
  notes in each `<aside>`). The online deck is built from the same files.
- `assets/` — images referenced by the slides (logo, demo screenshots with dummy cards only).
- Rebuild the PDF: `node docs/pitch/deck/build-pdf.mjs` (needs `npm i` in `app/verifier-demo` and Chrome).
