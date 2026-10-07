import { useEffect, useState } from 'react'
import QRCode from 'qrcode'
import { proofToClaim } from './lib/zkGate'
import type { Groth16Proof, ProveResult } from './lib/prover'
import type { ProofRequest } from './Phone'

type RelayResult = { proof: Groth16Proof & { pi_a: string[]; pi_b: string[][]; pi_c: string[] }; publicSignals: string[]; nonce: string }

const isLoopback = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname)

/** Hands the request to the real iPhone app: QR -> pipon://prove?s=<session URL>; the app posts the proof back. */
export function RealPhone({ request, onResult }: { request: ProofRequest | null; onResult: (r: ProveResult) => void }) {
  const [qr, setQr] = useState<string | null>(null)
  const [link, setLink] = useState('')
  const [status, setStatus] = useState<'idle' | 'waiting' | 'done' | 'error'>('idle')

  useEffect(() => {
    if (!request) return
    let stop = false
    const started = Date.now()
    setStatus('waiting')
    ;(async () => {
      const r = await fetch('/api/session', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(request),
      })
      if (!r.ok) return setStatus('error')
      const { id } = await r.json()
      const sessionUrl = `${location.origin}/api/session/${id}`
      const deepLink = `pipon://prove?s=${encodeURIComponent(sessionUrl)}`
      setLink(deepLink)
      setQr(await QRCode.toDataURL(deepLink, { margin: 1, width: 240 }))
      while (!stop) {
        await new Promise((res) => setTimeout(res, 1500))
        const p = await fetch(sessionUrl)
        if (!p.ok) return setStatus('error')
        const { result } = (await p.json()) as { result: RelayResult | null }
        if (result) {
          setStatus('done')
          onResult({
            claim: proofToClaim(result.proof, result.publicSignals, result.nonce),
            proof: result.proof,
            publicSignals: result.publicSignals,
            ms: Date.now() - started,
          })
          return
        }
      }
    })().catch(() => setStatus('error'))
    return () => {
      stop = true
    }
  }, [request, onResult])

  return (
    <div className="phone">
      <div className="phone-notch" />
      <div className="phone-screen">
        <div className="phone-title">Your iPhone</div>
        {!request ? (
          <p className="muted">Waiting for a request from a service…</p>
        ) : (
          <div className="request">
            <div className="request-from">Scan with the iPhone camera</div>
            {qr && <img className="qr" src={qr} alt="QR code that opens the p!pon app" />}
            <ul className="claims">
              {request.statement.map((s) => <li key={s}>{s}</li>)}
            </ul>
            {link && <div className="mono small muted break">{link}</div>}
          </div>
        )}
        <ol className="stages">
          <li className={status === 'waiting' ? 'active' : status === 'done' ? 'ok' : ''}>Tap your My Number Card on the iPhone</li>
          <li className={status === 'done' ? 'ok' : ''}>Proof received from the phone</li>
        </ol>
        {isLoopback && request && (
          <p className="bad-text small">Open this page via the Mac's LAN address (npm run dev -- --host) so the phone can reach it.</p>
        )}
        {status === 'error' && <p className="bad-text small">Relay error — is the demo server running?</p>}
      </div>
    </div>
  )
}
