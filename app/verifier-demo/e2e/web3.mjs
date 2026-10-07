// Web3 gated mint on devnet with the "Real iPhone app" phone mode and the dev burner wallet.
// The phone is the iOS simulator, or PHONE=mac for the macOS reader CLI (CARD=reader: the card in the USB reader).
import { chromium } from 'playwright-core'
import { execFileSync, spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const BASE = process.env.BASE ?? 'http://localhost:5173'
const CARD = process.env.CARD ?? 'tokyo20'
const OUT = process.env.OUT ?? '.'
const SIM = process.env.SIM ?? 'iPhone 17'
const GATE = process.env.GATE ?? '1' // 1: demo gate (dummy CA), 2: real cards (J-LIS CA), 3: real cards, test gate
const PHONE = process.env.PHONE ?? 'sim'
const browser = await chromium.launch({ executablePath: process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' })
const page = await browser.newPage({ viewport: { width: 1280, height: 1000 } })
page.on('pageerror', (e) => console.log('pageerror', e.message))
await page.goto(BASE)
await page.locator('.phone-mode select').selectOption('iphone')

await page.locator('.gate-pick select').selectOption(GATE)
await page.getByRole('button', { name: /Select Wallet/ }).click()
await page.getByRole('button', { name: /Burner/ }).click()
await page.getByRole('button', { name: 'Request proof' }).click()
const link = (await page.locator('.mono.small.muted.break').textContent({ timeout: 15000 })).trim()
const session = decodeURIComponent(link.split('s=')[1])
const { request } = await (await fetch(session)).json()
console.log('wallet', request.binding, '| service', request.service, '|', request.statement.join(', '))

const sol = (...a) => execFileSync(process.env.HOME + '/.local/share/solana/install/active_release/bin/solana', a, { encoding: 'utf8' })
console.log(sol('transfer', request.binding, '0.05', '--allow-unfunded-recipient', '-u', 'devnet').trim().split('\n').pop())

const t0 = Date.now()
const st = async () => { const r = await fetch(session); return r.status + (r.ok && (await r.json()).result ? ' +result' : '') }
if (PHONE === 'mac') {
  const cli = fileURLToPath(new URL('../../mobile/ZkCredMac/.build/release/zkcred-mac', import.meta.url))
  const run = spawnSync(cli, ['prove', link, ...(CARD === 'reader' ? [] : ['--dev', CARD])], { stdio: 'inherit' })
  if (run.status !== 0) console.log('zkcred-mac exited with', run.status)
} else {
  const sim = (...a) => execFileSync('xcrun', ['simctl', ...a], { stdio: 'pipe' })
  try { sim('terminate', SIM, 'app.pipon.ios') } catch {}
  sim('launch', SIM, 'app.pipon.ios', '-autoDevCard', CARD, '-openLink', link)
  console.log('session before launch:', await st())
}
for (let i = 0; i < 40; i++) {
  await new Promise((r) => setTimeout(r, 3000))
  const cur = (await page.locator('.mono.small.muted.break').textContent()).trim()
  console.log(`t=${((Date.now() - t0) / 1000).toFixed(0)}s session ${await st()}${cur !== link ? ' (page now shows a NEW link)' : ''}`)
  if (await page.locator('.stages li.ok', { hasText: 'Proof received' }).count()) break
}
await page.locator('.stages li.ok', { hasText: 'Proof received' }).waitFor({ timeout: 5000 })
console.log(`proof received after ${((Date.now() - t0) / 1000).toFixed(1)} s`)

await page.getByRole('button', { name: 'Mint' }).click()
const outcome = page.locator('.result')
await outcome.waitFor({ timeout: 300000 })
console.log('outcome:', (await outcome.textContent()).replace(/\s+/g, ' ').trim())
const links = await outcome.locator('a').evaluateAll((as) => as.map((a) => a.href))
if (links.length) console.log(links.join('\n'))
await page.screenshot({ path: `${OUT}/web3-result.png`, fullPage: true })
await browser.close()
