// Create a real-card gate on devnet: age 20+, all 47 prefectures, trusting the J-LIS signing CAs.
//   WALLET_KEYPAIR=~/.config/solana/zkcred-devnet.json [SCOPE=3 NAME="..."] node scripts/create-jlis-gate.cjs
// Scope 2 is the demo's real-card gate; scope 3 is for tests (each card claims once per scope).
// caKeyHash values: node circuits/scripts/export_solana.cjs cahash circuits/fixtures/jlis/*.cer
// signca01 expired on 2025-10-19 and is left out.
const fs = require("fs");
const os = require("os");
const { Connection, Keypair, Transaction, sendAndConfirmTransaction, clusterApiUrl } = require("@solana/web3.js");
const { gatePda, initializeGateIx } = require("../src/zkGate.cjs");

const SCOPE = Number(process.env.SCOPE || 2);
const CA_KEY_HASHES = [
  "0f8b63a80a1d2072363fd99ae06672d403b8ea2506aefba46c1076edd32f2e93", // signca02 (until 2029-09-14)
  "019d96eda27d0ab684f26405ef59ff856afd20fe36b9932a8a28434e6e55dfb8", // signca03 (until 2033-07-15)
];

(async () => {
  const conn = new Connection(process.env.RPC_URL || clusterApiUrl("devnet"), "confirmed");
  const path = process.env.WALLET_KEYPAIR.replace(/^~/, os.homedir());
  const payer = Keypair.fromSecretKey(Uint8Array.from(JSON.parse(fs.readFileSync(path))));
  const gate = gatePda(SCOPE);
  if (await conn.getAccountInfo(gate)) {
    console.log("gate exists", gate.toBase58());
    return;
  }
  const ix = initializeGateIx(payer.publicKey, {
    scope: SCOPE,
    minAge: 20,
    allowedPrefectures: Array.from({ length: 47 }, (_, i) => i + 1),
    caKeyHashes: CA_KEY_HASHES,
    name: process.env.NAME || "zkCredentials Japan 20+",
    uri: process.env.METADATA_URI || "https://example.com/zkcred/japan.json",
  });
  const sig = await sendAndConfirmTransaction(conn, new Transaction().add(ix), [payer]);
  console.log("gate created", gate.toBase58(), "authority", payer.publicKey.toBase58());
  console.log(`https://explorer.solana.com/tx/${sig}?cluster=devnet`);
})();
