// Web2 age check with the "Real iPhone app" phone mode, the iPhone being the iOS simulator.
import { chromium } from 'playwright-core'
import { execFileSync } from 'node:child_process'

const BASE = process.env.BASE ?? 'http://localhost:5173'
const CARD = process.env.CARD ?? 'tokyo20'
const OUT = process.env.OUT ?? '.'
const SIM = process.env.SIM ?? 'iPhone 17'
const browser = await chromium.launch({ executablePath: process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' })
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } })
page.on('pageerror', (e) => console.log('pageerror', e.message))
await page.goto(BASE)
await page.getByRole('tab', { name: /Web2/ }).click()
await page.locator('.phone-mode select').selectOption('iphone')
await page.getByRole('button', { name: /Verify age with zkCredentials/ }).click()
const link = (await page.locator('.mono.small.muted.break').textContent({ timeout: 15000 })).trim()
console.log('deep link', link.slice(0, 60) + '…')
await page.screenshot({ path: `${OUT}/web2-qr.png` })

const sim = (...a) => execFileSync('xcrun', ['simctl', ...a], { stdio: 'pipe' })
try { sim('terminate', SIM, 'app.zkcredentials.ios') } catch {}
const t0 = Date.now()
sim('launch', SIM, 'app.zkcredentials.ios', '-autoDevCard', CARD, '-openLink', link)

const verdict = page.locator('.result strong')
await verdict.waitFor({ timeout: 120000 })
console.log('verdict', await verdict.textContent(), `after ${((Date.now() - t0) / 1000).toFixed(1)} s`)
for (const li of await page.locator('.checks li').all()) console.log(' ', (await li.getAttribute('class')) === 'ok' ? 'OK ' : 'NG ', await li.textContent())
await page.screenshot({ path: `${OUT}/web2-result.png`, fullPage: true })
sim('io', SIM, 'screenshot', `${OUT}/web2-phone.png`)
await browser.close()
