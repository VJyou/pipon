// Render the pitch deck (slides/*.html in deck.json order, 1920×1080 each) to pipon-pitch.pdf.
// The slides are the source of the online deck; this is a plain-browser approximation of its renderer:
// <x-icon> and <x-shape> become inline SVG, speaker notes (<aside>) are hidden, /_blob/<id> maps to assets/<id>.png.
//   node docs/pitch/deck/build-pdf.mjs      (uses playwright-core from app/verifier-demo and the local Chrome)
import { readFileSync, readdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'

const here = fileURLToPath(new URL('.', import.meta.url))
const require = createRequire(new URL('../../../app/verifier-demo/package.json', import.meta.url))
const { chromium } = require('playwright-core')

const deck = JSON.parse(readFileSync(here + 'deck.json', 'utf8'))
const ids = [...deck.order, ...readdirSync(here + 'slides').map((f) => f.replace(/\.html$/, '')).filter((id) => !deck.order.includes(id))]

const svg = (body, style) => `<svg viewBox="0 0 24 24" style="${style}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${body}</svg>`
const ICONS = {
  Warning: '<path d="M12 3 2 21h20L12 3z"/><path d="M12 10v5"/><circle cx="12" cy="18" r="0.6"/>',
  CheckCircle: '<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>',
  Users: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c0-3.6 2.9-6 6.5-6s6.5 2.4 6.5 6"/><circle cx="17" cy="9" r="2.5"/><path d="M17 14c2.6 0 4.5 2 4.5 5"/>',
  Trust: '<path d="M12 3 4 6v6c0 4.5 3.4 8.3 8 9 4.6-.7 8-4.5 8-9V6l-8-3z"/><path d="m8.5 12 2.5 2.5 4.5-5"/>',
  Lightning: '<path d="M13 2 4 14h7l-1 8 9-12h-7l1-8z"/>',
}
const style = (attrs) => (attrs.match(/style="([^"]*)"/) || [])[1] || ''

function convert(html) {
  return html
    // inlined: a page set with setContent cannot load file:// images
    .replace(/src="\/_blob\/([0-9a-f]+)"/g, (_, id) => `src="data:image/png;base64,${readFileSync(here + 'assets/' + id + '.png').toString('base64')}"`)
    .replace(/<x-icon name="(\w+)"([^>]*)><\/x-icon>/g, (_, name, a) => svg(ICONS[name] ?? '<circle cx="12" cy="12" r="9"/>', style(a) + ';flex:none'))
    .replace(/<x-shape kind="arrow-right"([^>]*)><\/x-shape>/g, (_, a) => {
      const fill = (style(a).match(/background:([^;]+)/) || [])[1] || '#000'
      return `<svg viewBox="0 0 72 36" style="${style(a).replace(/background:[^;]+;?/, '')};flex:none"><path d="M0 11h43V0l29 18-29 18V25H0z" fill="${fill}"/></svg>`
    })
}

const fonts = Object.values(deck.faces).map((f) => `<link rel="stylesheet" href="${f.href}">`).join('')
const page = `<!doctype html><html><head><meta charset="utf-8">${fonts}<style>
  @page { size: 1920px 1080px; margin: 0 }
  * { margin: 0; box-sizing: border-box }
  html, body { width: 1920px }
  section { width: 1920px; height: 1080px; position: relative; overflow: hidden; break-after: page }
  aside { display: none }
  h1 { font-size: 96px } h2 { font-size: 64px } h3 { font-size: 44px; line-height: 1.2 } p { font-size: 32px; line-height: 1.4 }
  table { border-collapse: collapse; width: 100% } th, td { padding: 0.35em 0.6em; border-bottom: 1px solid rgba(127,127,127,.35); text-align: left }
</style></head><body>${ids.map((id) => convert(readFileSync(`${here}slides/${id}.html`, 'utf8'))).join('\n')}</body></html>`

const browser = await chromium.launch({ executablePath: process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' })
const tab = await browser.newPage({ viewport: { width: 1920, height: 1080 } })
await tab.setContent(page, { waitUntil: 'networkidle' })
await tab.evaluate(() => document.fonts.ready)
await tab.pdf({ path: here + 'pipon-pitch.pdf', width: '1920px', height: '1080px', printBackground: true })
if (process.env.PNG) {
  const sections = await tab.locator('section').all()
  for (const [i, s] of sections.entries()) await s.screenshot({ path: `${process.env.PNG}/${String(i + 1).padStart(2, '0')}-${ids[i]}.png` })
}
await browser.close()
console.log(`pipon-pitch.pdf: ${ids.length} slides`)
