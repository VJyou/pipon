// Talks to server/mock-prover.mjs, which stands in for the phone app (NFC read + on-device proving).
import type { Claim } from './zkGate'

export type Groth16Proof = Record<string, unknown>
export type ProveResult = { claim: Claim; proof: Groth16Proof; publicSignals: string[]; ms: number }

export class Unsatisfiable extends Error {}

/** This browser's own dummy card ("guest" persona): a random id kept in localStorage. */
function guestId(): string {
  const fresh = () => Array.from(crypto.getRandomValues(new Uint8Array(16)), (b) => b.toString(16).padStart(2, '0')).join('')
  try {
    const id = localStorage.getItem('pipon-guest') ?? fresh()
    localStorage.setItem('pipon-guest', id)
    return id
  } catch {
    return (sessionGuest ??= fresh())
  }
}
let sessionGuest: string | undefined

export async function fetchPersonas(): Promise<Record<string, string>> {
  const r = await fetch('/api/personas')
  if (!r.ok) throw new Error('mock prover is not running (node server/mock-prover.mjs)')
  return r.json()
}

/**
 * @param binding wallet pubkey (base58) or a 32-byte hex session id the card's signature is bound to
 * @param scope service id; the nullifier is unique per (card, scope), so services cannot link users
 */
export async function prove(binding: string, persona: string, scope: number): Promise<ProveResult> {
  const r = await fetch('/api/prove', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ binding, persona, scope, guestId: guestId() }),
  })
  if (r.status === 422) throw new Unsatisfiable('This card does not satisfy the request')
  if (r.status === 429 || r.status === 503) throw new Error((await r.json().catch(() => null))?.error ?? 'the demo prover is busy')
  if (!r.ok) throw new Error(`prover error (${r.status})`)
  return r.json()
}

export async function fetchVkey(): Promise<unknown> {
  const r = await fetch('/api/vkey')
  if (!r.ok) throw new Error('vkey unavailable')
  return r.json()
}
