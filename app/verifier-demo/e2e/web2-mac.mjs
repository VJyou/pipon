// Web2 age check with the "Real iPhone app" phone mode, answered by the macOS backup CLI (app/mobile/ZkCredMac).
// CARD=<dummy card> uses a bundled test card; CARD=reader reads the card in the USB reader (asks for the password).
import { chromium } from 'playwright-core'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const BASE = process.env.BASE ?? 'http://localhost:5173'
const CARD = process.env.CARD ?? 'tokyo20'
const OUT = process.env.OUT ?? '.'
const CLI = fileURLToPath(new URL('../../mobile/ZkCredMac/.build/release/zkcred-mac', import.meta.url))
const browser = await chromium.launch({ executablePath: process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' })
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } })
page.on('pageerror', (e) => console.log('pageerror', e.message))
await page.goto(BASE)
await page.getByRole('tab', { name: /Web2/ }).click()
await page.locator('.phone-mode select').selectOption('iphone')
await page.getByRole('button', { name: /Verify age with zkCredentials/ }).click()
const link = (await page.locator('.mono.small.muted.break').textContent({ timeout: 15000 })).trim()
console.log('deep link', link.slice(0, 60) + '…')

const t0 = Date.now()
const args = ['prove', link, ...(CARD === 'reader' ? [] : ['--dev', CARD])]
const run = spawnSync(CLI, args, { stdio: 'inherit' })
if (run.status !== 0) console.log('zkcred-mac exited with', run.status)

const verdict = page.locator('.result strong')
await verdict.waitFor({ timeout: 30000 })
console.log('verdict', await verdict.textContent(), `after ${((Date.now() - t0) / 1000).toFixed(1)} s`)
for (const li of await page.locator('.checks li').all()) console.log(' ', (await li.getAttribute('class')) === 'ok' ? 'OK ' : 'NG ', await li.textContent())
await page.screenshot({ path: `${OUT}/web2-mac-result.png`, fullPage: true })
await browser.close()
