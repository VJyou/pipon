// Create the demo gate for dummy cards on devnet: scope 5, age 20+, Tokyo only, trusting the dummy CA.
// Replaces scope 1 in the web demo after the rename to p!pon (scope 1 is named "zkCredentials Tokyo 20+"; gate names
// are immutable).
//   WALLET_KEYPAIR=~/.config/solana/zkcred-devnet.json node scripts/create-demo-gate.cjs
// caKeyHash: node circuits/scripts/export_solana.cjs cahash circuits/build/dev-cards/dummy-ca.der
const fs = require("fs");
const os = require("os");
const { Connection, Keypair, Transaction, sendAndConfirmTransaction, clusterApiUrl } = require("@solana/web3.js");
const { gatePda, initializeGateIx } = require("../src/zkGate.cjs");

const SCOPE = Number(process.env.SCOPE || 5);
const DUMMY_CA_KEY_HASH = "02e6679fa9e67dafedc92a91beb4678a66607b5819c4eb6270698fd36ca740d6";

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
    allowedPrefectures: [13], // Tokyo
    caKeyHashes: [DUMMY_CA_KEY_HASH],
    name: process.env.NAME || "p!pon Tokyo 20+",
    uri: process.env.METADATA_URI || "https://example.com/pipon/tokyo.json",
  });
  const sig = await sendAndConfirmTransaction(conn, new Transaction().add(ix), [payer]);
  console.log("gate created", gate.toBase58(), "authority", payer.publicKey.toBase58());
  console.log(`https://explorer.solana.com/tx/${sig}?cluster=devnet`);
})();
