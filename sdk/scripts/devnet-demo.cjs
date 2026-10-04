// Devnet demo: (1) create the gate if missing, (2) claim with a proof bound to the wallet, (3) replay -> rejected.
//   WALLET_KEYPAIR=~/.config/solana/zkcred-devnet.json CLAIM=../circuits/build/devnet/claim.json node scripts/devnet-demo.cjs
const fs = require("fs");
const os = require("os");
const { Connection, Keypair, Transaction, sendAndConfirmTransaction, clusterApiUrl } = require("@solana/web3.js");
const { gatePda, initializeGateIx, claimIxs } = require("../src/zkGate.cjs");

const expand = (p) => p.replace(/^~/, os.homedir());
const SCOPE = 1;

(async () => {
  const conn = new Connection(process.env.RPC_URL || clusterApiUrl("devnet"), "confirmed");
  const payer = Keypair.fromSecretKey(
    Uint8Array.from(JSON.parse(fs.readFileSync(expand(process.env.WALLET_KEYPAIR)))),
  );
  const claim = JSON.parse(fs.readFileSync(process.env.CLAIM));
  const send = (ixs, extra = []) =>
    sendAndConfirmTransaction(conn, new Transaction().add(...ixs), [payer, ...extra]);

  const gate = gatePda(SCOPE);
  if (!(await conn.getAccountInfo(gate))) {
    const sig = await send([
      initializeGateIx(payer.publicKey, {
        scope: SCOPE,
        minAge: 20,
        allowedPrefectures: [13], // 東京都
        caKeyHashes: [claim.public_inputs[0]],
        name: "zkCredentials Tokyo 20+",
        uri: process.env.METADATA_URI || "https://example.com/zkcred/tokyo.json",
      }),
    ]);
    console.log("gate created", gate.toBase58(), sig);
  } else {
    console.log("gate exists", gate.toBase58());
  }

  const asset = Keypair.generate();
  const sig = await send(claimIxs(payer.publicKey, asset.publicKey, SCOPE, claim), [asset]);
  const tx = await conn.getTransaction(sig, { maxSupportedTransactionVersion: 0, commitment: "confirmed" });
  console.log("claimed", sig, "CU", tx?.meta?.computeUnitsConsumed);
  console.log("asset", asset.publicKey.toBase58());
  console.log(`https://explorer.solana.com/address/${asset.publicKey.toBase58()}?cluster=devnet`);

  try {
    const again = Keypair.generate();
    await send(claimIxs(payer.publicKey, again.publicKey, SCOPE, claim), [again]);
    console.log("REPLAY ACCEPTED (unexpected)");
    process.exit(1);
  } catch (e) {
    console.log("replay rejected as expected");
  }
})();
