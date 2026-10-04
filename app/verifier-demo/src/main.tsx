import { Buffer } from 'buffer'
;(globalThis as unknown as { Buffer: typeof Buffer }).Buffer ??= Buffer

import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { ConnectionProvider, WalletProvider } from '@solana/wallet-adapter-react'
import { WalletModalProvider } from '@solana/wallet-adapter-react-ui'
import { UnsafeBurnerWalletAdapter } from '@solana/wallet-adapter-unsafe-burner'
import '@solana/wallet-adapter-react-ui/styles.css'
import './index.css'
import App from './App.tsx'

const RPC = import.meta.env.VITE_RPC_URL ?? 'https://api.devnet.solana.com'
// Dev/test only: an in-browser keypair wallet (VITE_BURNER=1). Never enable for real funds.
const wallets = import.meta.env.VITE_BURNER === '1' ? [new UnsafeBurnerWalletAdapter()] : []

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ConnectionProvider endpoint={RPC}>
      {/* Wallet Standard wallets (Phantom, Solflare, Backpack...) are detected automatically. */}
      <WalletProvider wallets={wallets} autoConnect>
        <WalletModalProvider>
          <App />
        </WalletModalProvider>
      </WalletProvider>
    </ConnectionProvider>
  </StrictMode>,
)
