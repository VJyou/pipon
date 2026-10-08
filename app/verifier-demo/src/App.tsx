import { useState } from 'react'
import { Phone, type ProofRequest } from './Phone'
import { RealPhone } from './RealPhone'
import { Web2Panel } from './Web2Panel'
import { Web3Panel } from './Web3Panel'
import type { ProveResult } from './lib/prover'

type Tab = 'web3' | 'web2'
type PhoneMode = 'simulated' | 'iphone'

export default function App() {
  const [tab, setTab] = useState<Tab>('web3')
  const [request, setRequest] = useState<ProofRequest | null>(null)
  const [result, setResult] = useState<ProveResult | null>(null)
  const [phone, setPhone] = useState<PhoneMode>('simulated')

  const ask = (r: ProofRequest) => {
    setResult(null)
    setRequest(r)
  }
  const switchTab = (t: Tab) => {
    setTab(t)
    setRequest(null)
    setResult(null)
  }

  return (
    <div className="app">
      <header className="top">
        <div className="brand">
          <img className="logo" src="/pipon-logo.png" alt="" /> p!pon
        </div>
        <p className="tagline">IC chips solve authenticity. Zero-knowledge credentials solve privacy.</p>
      </header>

      <nav className="tabs" role="tablist">
        <button role="tab" aria-selected={tab === 'web3'} onClick={() => switchTab('web3')}>Web3 · Gated mint</button>
        <button role="tab" aria-selected={tab === 'web2'} onClick={() => switchTab('web2')}>Web2 · Age check</button>
        <label className="phone-mode">
          Phone
          <select
            value={phone}
            onChange={(e) => {
              setPhone(e.target.value as PhoneMode)
              setRequest(null)
              setResult(null)
            }}
          >
            <option value="simulated">Simulated (dummy cards)</option>
            <option value="iphone">Real iPhone app</option>
          </select>
        </label>
      </nav>

      {phone === 'simulated' && (
        <section className="demo-note" aria-label="How this demo works">
          <strong>How this demo works.</strong> In the real p!pon app you tap your My Number Card on an iPhone (NFC) and
          the proof is made on the phone. Here the phone on the left is <b>simulated</b>: a <b>dummy card</b> issued by a
          test authority stands in for your card, and our demo server makes the proof with the same circuit. The service on
          the right receives only the proof.
          <ol>
            <li>Press the service's button on the right</li>
            <li>On the simulated phone, press <i>Simulate card tap &amp; prove</i></li>
            <li>See what the service checks — and what it never sees</li>
          </ol>
        </section>
      )}

      <main className="stage">
        {phone === 'simulated' ? (
          <Phone request={request} onResult={setResult} />
        ) : (
          <RealPhone request={request} onResult={setResult} />
        )}
        <div className="flow" aria-hidden>
          <span>request →</span>
          <span>← proof only</span>
        </div>
        {tab === 'web3' ? <Web3Panel result={result} onRequest={ask} /> : <Web2Panel result={result} onRequest={ask} />}
      </main>

      <footer className="foot">
        {phone === 'simulated'
          ? 'Simulated phone: dummy certificates from a test CA stand in for the My Number Card, which the real app reads over NFC; the demo server proves with the real circuit (1.49M constraints, Groth16). No real personal data is used.'
          : 'Real iPhone app: the phone reads the My Number Card over NFC and makes the proof on the device (1.49M constraints, Groth16). Only the proof and the facts above reach this page; the card data never leaves the phone.'}
      </footer>
    </div>
  )
}
