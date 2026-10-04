import { useCallback, useEffect, useState } from 'react'
import { useConnection, useWallet } from '@solana/wallet-adapter-react'
import { WalletMultiButton } from '@solana/wallet-adapter-react-ui'
import { Keypair, Transaction } from '@solana/web3.js'
import { claimIxs, fetchGate, gatePda, PREFECTURES, PROGRAM_ERRORS, type Gate } from './lib/zkGate'
import type { ProveResult } from './lib/prover'
import type { ProofRequest } from './Phone'

const SCOPE = 1
const explorer = (kind: 'address' | 'tx', id: string) => `https://explorer.solana.com/${kind}/${id}?cluster=devnet`

type Outcome = { ok: true; asset: string; sig: string } | { ok: false; reason: string }

function explain(logs: string[] | null | undefined, err: unknown): string {
  const text = (logs ?? []).join('\n')
  // The nullifier PDA already exists -> the system program refuses to create it again.
  if (/already in use/.test(text)) return 'Already claimed — this card’s nullifier is on-chain (one per person).'
  const code = Number(/Error Number: (\d+)/.exec(text)?.[1])
  return PROGRAM_ERRORS[code] ?? JSON.stringify(err)
}

export function Web3Panel({ result, onRequest }: { result: ProveResult | null; onRequest: (r: ProofRequest) => void }) {
  const { connection } = useConnection()
  const { publicKey, sendTransaction } = useWallet()
  const [gate, setGate] = useState<Gate | null>(null)
  const [busy, setBusy] = useState(false)
  const [outcome, setOutcome] = useState<Outcome | null>(null)

  const refresh = useCallback(() => fetchGate(connection, SCOPE).then(setGate), [connection])
  useEffect(() => {
    refresh()
  }, [refresh])

  const ready = result && publicKey
  const prefs = gate?.allowedPrefectures.map((c) => PREFECTURES[c - 1]).join('・')

  function request() {
    if (!publicKey || !gate) return
    setOutcome(null)
    onRequest({
      binding: publicKey.toBase58(),
      scope: SCOPE,
      service: gate.name,
      statement: [`Age ${gate.minAge}+`, `Lives in ${prefs}`, 'Has not claimed before'],
    })
  }

  async function mint() {
    if (!result || !publicKey) return
    setBusy(true)
    setOutcome(null)
    try {
      const asset = Keypair.generate()
      const tx = new Transaction().add(...claimIxs(publicKey, asset.publicKey, SCOPE, result.claim))
      tx.feePayer = publicKey
      tx.recentBlockhash = (await connection.getLatestBlockhash()).blockhash
      // Simulate first so a rejection shows the program's reason instead of a wallet error.
      const sim = await connection.simulateTransaction(tx)
      if (sim.value.err) {
        setOutcome({ ok: false, reason: explain(sim.value.logs, sim.value.err) })
        return
      }
      const sig = await sendTransaction(tx, connection, { signers: [asset] })
      await connection.confirmTransaction(sig, 'confirmed')
      setOutcome({ ok: true, asset: asset.publicKey.toBase58(), sig })
      refresh()
    } catch (e) {
      setOutcome({ ok: false, reason: String((e as Error).message ?? e) })
    } finally {
      setBusy(false)
    }
  }

  return (
    <section className="panel">
      <header className="panel-head">
        <div>
          <div className="eyebrow">Web3 · Solana devnet</div>
          <h2>{gate?.name ?? 'Gated mint'}</h2>
        </div>
        <WalletMultiButton />
      </header>

      {gate ? (
        <dl className="facts">
          <div><dt>Requires</dt><dd>Age {gate.minAge}+ · {prefs}</dd></div>
          <div><dt>Claimed</dt><dd>{gate.claimed.toString()}</dd></div>
          <div><dt>Gate</dt><dd><a href={explorer('address', gatePda(SCOPE).toBase58())} target="_blank">{gatePda(SCOPE).toBase58().slice(0, 8)}…</a></dd></div>
        </dl>
      ) : (
        <p className="muted">Loading gate from devnet…</p>
      )}

      <ol className="steps">
        <li className={publicKey ? 'ok' : 'active'}>Connect a wallet (devnet)</li>
        <li className={result ? 'ok' : publicKey ? 'active' : ''}>
          Ask the phone for a proof bound to this wallet
          <button onClick={request} disabled={!publicKey || !gate}>Request proof</button>
        </li>
        <li className={outcome?.ok ? 'ok' : ready ? 'active' : ''}>
          Verify on-chain (Groth16 + nullifier) and mint
          <button className="primary" onClick={mint} disabled={!ready || busy}>{busy ? 'Submitting…' : 'Mint'}</button>
        </li>
      </ol>

      {outcome?.ok && (
        <div className="result ok-box">
          <strong>Minted.</strong> The program verified the proof and recorded the nullifier.
          <div><a href={explorer('address', outcome.asset)} target="_blank">View NFT</a> · <a href={explorer('tx', outcome.sig)} target="_blank">Transaction</a></div>
          <div className="small muted">Try again with the same card: a new proof gives the same nullifier, so it is rejected.</div>
        </div>
      )}
      {outcome && !outcome.ok && (
        <div className="result bad-box"><strong>Rejected.</strong> {outcome.reason}</div>
      )}
    </section>
  )
}
