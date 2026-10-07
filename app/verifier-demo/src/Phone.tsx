import { useEffect, useState } from 'react'
import { fetchPersonas, prove, Unsatisfiable, type ProveResult } from './lib/prover'

export type ProofRequest = { binding: string; scope: number; service: string; statement: string[] }

type Stage = 'idle' | 'reading' | 'proving' | 'done' | 'unsatisfiable' | 'error'

const NEVER_LEAVES = ['Name', 'Date of birth', 'Street address', 'Individual Number (never read)']

export function Phone({ request, onResult }: { request: ProofRequest | null; onResult: (r: ProveResult) => void }) {
  const [personas, setPersonas] = useState<Record<string, string>>({})
  const [persona, setPersona] = useState('tokyo20')
  const [stage, setStage] = useState<Stage>('idle')
  const [ms, setMs] = useState(0)
  const [err, setErr] = useState('')

  useEffect(() => {
    fetchPersonas().then(setPersonas).catch((e) => setErr(String(e.message)))
  }, [])
  useEffect(() => setStage('idle'), [request])

  async function run() {
    if (!request) return
    setErr('')
    setStage('reading')
    // The real app reads the JPKI signing certificate over NFC here (password required).
    await new Promise((r) => setTimeout(r, 900))
    setStage('proving')
    try {
      const res = await prove(request.binding, persona, request.scope)
      setMs(res.ms)
      setStage('done')
      onResult(res)
    } catch (e) {
      if (e instanceof Unsatisfiable) setStage('unsatisfiable')
      else {
        setStage('error')
        setErr(String((e as Error).message))
      }
    }
  }

  return (
    <div className="phone">
      <div className="phone-notch" />
      <div className="phone-screen">
        <div className="phone-title">p!pon</div>
        <label className="field">
          <span>Dummy card</span>
          <select value={persona} onChange={(e) => setPersona(e.target.value)} disabled={stage === 'reading' || stage === 'proving'}>
            {Object.entries(personas).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
        </label>

        {!request ? (
          <p className="muted">Waiting for a request from a service…</p>
        ) : (
          <div className="request">
            <div className="request-from">{request.service} asks you to prove:</div>
            <ul className="claims">
              {request.statement.map((s) => <li key={s}>{s}</li>)}
            </ul>
            <div className="mono small muted">bound to {request.binding.slice(0, 6)}…{request.binding.slice(-4)}</div>
            <details className="never">
              <summary>Stays on this phone</summary>
              <ul>{NEVER_LEAVES.map((s) => <li key={s}>{s}</li>)}</ul>
            </details>
            <button className="primary wide" onClick={run} disabled={stage === 'reading' || stage === 'proving'}>
              {stage === 'idle' || stage === 'done' || stage === 'unsatisfiable' || stage === 'error'
                ? 'Tap My Number Card & prove'
                : 'Working…'}
            </button>
          </div>
        )}

        <ol className="stages">
          <li className={stage === 'reading' ? 'active' : ['proving', 'done'].includes(stage) ? 'ok' : ''}>Read IC chip (signed by J-LIS)</li>
          <li className={stage === 'proving' ? 'active' : stage === 'done' ? 'ok' : stage === 'unsatisfiable' ? 'bad' : ''}>
            Generate ZK proof on device
          </li>
          <li className={stage === 'done' ? 'ok' : ''}>Send proof only{stage === 'done' && ` · ${(ms / 1000).toFixed(1)}s`}</li>
        </ol>
        {stage === 'unsatisfiable' && <p className="bad-text">No proof exists: this card does not meet the request.</p>}
        {err && <p className="bad-text small">{err}</p>}
      </div>
    </div>
  )
}
