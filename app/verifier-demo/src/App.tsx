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
        Demo with dummy certificates issued by a dummy CA. The phone is simulated by a local prover running the real circuit
        (1.49M constraints, Groth16). No real personal data is used.
      </footer>
    </div>
  )
}
