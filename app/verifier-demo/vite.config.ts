import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [react()],
  define: { global: 'globalThis' },
  server: {
    // mock prover (server/mock-prover.mjs) stands in for the phone app
    proxy: { '/api': 'http://127.0.0.1:8787' },
  },
})
