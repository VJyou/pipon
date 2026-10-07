import { useEffect, useState } from 'react'
import { useConnection } from '@solana/wallet-adapter-react'
import * as snarkjs from 'snarkjs'
import { challengeHalves, fetchGate, fromHex, PREFECTURES, toHex } from './lib/zkGate'
import { fetchVkey, type ProveResult } from './lib/prover'
import type { ProofRequest } from './Phone'

type Check = { label: string; ok: boolean }
type Verdict = { checks: Check[]; ms: number; prefecture: string; nullifier: string }

// This shop's own scope: its pseudonymous IDs differ from the gate's (scope 1) for the same card.
const SHOP_SCOPE = 1001

const todayJst = () => Number(new Date(Date.now() + 9 * 3600_000).toISOString().slice(0, 10).replaceAll('-', ''))

/** A regular website (no wallet): verifies the proof in the browser, trusting CA keys published on Solana. */
export function Web2Panel({ result, onRequest }: { result: ProveResult | null; onRequest: (r: ProofRequest) => void }) {
  const { connection } = useConnection()
  const [session, setSession] = useState<string | null>(null)
  const [verdict, setVerdict] = useState<Verdict | null>(null)

  function request() {
    const s = toHex(crypto.getRandomValues(new Uint8Array(32)))
    setSession(s)
    setVerdict(null)
    onRequest({ binding: s, scope: SHOP_SCOPE, service: 'Sakaya Online', statement: ['Age 20+'] })
  }

  useEffect(() => {
    if (!result || !session) return
    ;(async () => {
      const t0 = performance.now()
      // Trust list: the CA keys of the demo's two devnet gates (scope 5: dummy CA, scope 4: J-LIS signing CAs).
      const [vkey, demoGate, jlisGate] = await Promise.all([fetchVkey(), fetchGate(connection, 5), fetchGate(connection, 4)])
      const trusted = [...(demoGate?.caKeyHashes ?? []), ...(jlisGate?.caKeyHashes ?? [])]
      // public = [caKeyHash, nullifier, chalHi, chalLo, currentDate, ageThreshold, prefectureCode, scope]
      const p = result.publicSignals.map(BigInt)
      const [hi, lo] = challengeHalves(fromHex(session), BigInt(result.claim.nonce))
      const caHex = p[0].toString(16).padStart(64, '0')
      const checks: Check[] = [
        { label: 'Groth16 proof is valid', ok: await snarkjs.groth16.verify(vkey, result.publicSignals, result.proof) },
        { label: 'Signed by the card for this session (no replay)', ok: p[2] === hi && p[3] === lo },
        { label: 'Issuer CA is in the on-chain trust list', ok: trusted.includes(caHex) },
        { label: 'Proof is for today (JST)', ok: Number(p[4]) === todayJst() },
        { label: 'Age 20 or over', ok: p[5] >= 20n },
        { label: 'Pseudonymous ID is scoped to this shop', ok: p[7] === BigInt(SHOP_SCOPE) },
      ]
      setVerdict({
        checks,
        ms: performance.now() - t0,
        prefecture: PREFECTURES[Number(p[6]) - 1] ?? '?',
        nullifier: p[1].toString(16).padStart(64, '0'),
      })
    })()
  }, [result, session, connection])

  const passed = verdict?.checks.every((c) => c.ok)

  return (
    <section className="panel">
      <header className="panel-head">
        <div>
          <div className="eyebrow">Web2 · no wallet, no signup</div>
          <h2>Sakaya Online</h2>
        </div>
      </header>
      <p>Alcohol can only be sold to people aged 20+. Today the shop asks for a photo of your ID card.</p>

      <button className="primary" onClick={request}>Verify age with p!pon</button>

      {verdict && (
        <div className={`result ${passed ? 'ok-box' : 'bad-box'}`}>
          <strong>{passed ? 'Age verified.' : 'Verification failed.'}</strong>
          <span className="small muted"> in {verdict.ms.toFixed(0)} ms, in your browser</span>
          <ul className="checks">
            {verdict.checks.map((c) => <li key={c.label} className={c.ok ? 'ok' : 'bad'}>{c.label}</li>)}
          </ul>
        </div>
      )}

      <div className="compare">
        <div>
          <h3>What the shop received</h3>
          {verdict ? (
            <ul>
              <li>Age ≥ 20: <b>yes</b></li>
              <li>Prefecture: {verdict.prefecture}</li>
              <li>Pseudonymous ID (this shop only): <span className="mono small">{verdict.nullifier.slice(0, 12)}…</span></li>
            </ul>
          ) : <p className="muted">Nothing yet.</p>}
        </div>
        <div>
          <h3>What it never sees</h3>
          <ul className="struck">
            <li>Name</li>
            <li>Date of birth</li>
            <li>Street address</li>
            <li>Card photo / My Number</li>
          </ul>
        </div>
      </div>
    </section>
  )
}
