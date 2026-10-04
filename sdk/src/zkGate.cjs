// Minimal client for programs/zk_gate (Anchor discriminators + borsh, no IDL runtime).
const crypto = require("crypto");
const {
  PublicKey,
  SystemProgram,
  TransactionInstruction,
  ComputeBudgetProgram,
} = require("@solana/web3.js");

const PROGRAM_ID = new PublicKey("AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK");
const MPL_CORE_ID = new PublicKey("CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d");

const disc = (name) => crypto.createHash("sha256").update(`global:${name}`).digest().subarray(0, 8);
const u8 = (x) => Buffer.from([x]);
const u32 = (x) => { const b = Buffer.alloc(4); b.writeUInt32LE(x); return b; };
const u64 = (x) => { const b = Buffer.alloc(8); b.writeBigUInt64LE(BigInt(x)); return b; };
const str = (s) => { const b = Buffer.from(s, "utf8"); return Buffer.concat([u32(b.length), b]); };
const hex = (h, n) => { const b = Buffer.from(h, "hex"); if (b.length !== n) throw new Error(`expected ${n} bytes`); return b; };

function gatePda(scope) {
  return PublicKey.findProgramAddressSync([Buffer.from("gate"), u64(scope)], PROGRAM_ID)[0];
}

function nullifierPda(gate, nullifier) {
  return PublicKey.findProgramAddressSync([Buffer.from("nullifier"), gate.toBuffer(), nullifier], PROGRAM_ID)[0];
}

/** @param {{scope, minAge, allowedPrefectures: number[], caKeyHashes: string[], name, uri}} g */
function initializeGateIx(authority, g) {
  const mask = g.allowedPrefectures.reduce((m, c) => m | (1n << BigInt(c - 1)), 0n);
  const data = Buffer.concat([
    disc("initialize_gate"),
    u64(g.scope),
    u8(g.minAge),
    u64(mask),
    u32(g.caKeyHashes.length),
    ...g.caKeyHashes.map((h) => hex(h, 32)),
    str(g.name),
    str(g.uri),
  ]);
  return new TransactionInstruction({
    programId: PROGRAM_ID,
    keys: [
      { pubkey: authority, isSigner: true, isWritable: true },
      { pubkey: gatePda(g.scope), isSigner: false, isWritable: true },
      { pubkey: SystemProgram.programId, isSigner: false, isWritable: false },
    ],
    data,
  });
}

/**
 * @param claim output of circuits/scripts/export_solana.cjs (claim.json)
 * @returns instructions; the asset keypair must co-sign.
 */
function claimIxs(claimer, asset, scope, claim) {
  const gate = gatePda(scope);
  const nullifier = hex(claim.public_inputs[1], 32);
  const data = Buffer.concat([
    disc("claim"),
    hex(claim.proof_a, 64),
    hex(claim.proof_b, 128),
    hex(claim.proof_c, 64),
    hex(claim.public_inputs[0], 32),
    nullifier,
    u32(Number(claim.current_date)),
    u8(Number(claim.prefecture_code)),
    u64(claim.nonce),
  ]);
  return [
    ComputeBudgetProgram.setComputeUnitLimit({ units: 300_000 }),
    new TransactionInstruction({
      programId: PROGRAM_ID,
      keys: [
        { pubkey: claimer, isSigner: true, isWritable: true },
        { pubkey: gate, isSigner: false, isWritable: true },
        { pubkey: nullifierPda(gate, nullifier), isSigner: false, isWritable: true },
        { pubkey: asset, isSigner: true, isWritable: true },
        { pubkey: MPL_CORE_ID, isSigner: false, isWritable: false },
        { pubkey: SystemProgram.programId, isSigner: false, isWritable: false },
      ],
      data,
    }),
  ];
}

module.exports = { PROGRAM_ID, MPL_CORE_ID, gatePda, nullifierPda, initializeGateIx, claimIxs };
