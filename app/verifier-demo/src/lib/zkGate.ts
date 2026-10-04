// Browser client for programs/zk_gate (same encoding as sdk/src/zkGate.cjs).
import { sha256 } from "@noble/hashes/sha2.js";
import {
  ComputeBudgetProgram,
  Connection,
  PublicKey,
  SystemProgram,
  TransactionInstruction,
} from "@solana/web3.js";
import { Buffer } from "buffer";

export const PROGRAM_ID = new PublicKey("AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK");
export const MPL_CORE_ID = new PublicKey("CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d");

/** claim.json from circuits/scripts/export_solana.cjs */
export type Claim = {
  proof_a: string;
  proof_b: string;
  proof_c: string;
  public_inputs: string[];
  nonce: string;
  current_date: string;
  prefecture_code: string;
};

export type Gate = {
  authority: PublicKey;
  scope: bigint;
  minAge: number;
  allowedPrefectures: number[];
  caKeyHashes: string[];
  claimed: bigint;
  name: string;
  uri: string;
};

const enc = new TextEncoder();
const dec = new TextDecoder();
const concat = (...xs: Uint8Array[]) => {
  const out = new Uint8Array(xs.reduce((n, x) => n + x.length, 0));
  let o = 0;
  for (const x of xs) {
    out.set(x, o);
    o += x.length;
  }
  return out;
};
const le = (x: bigint | number, n: number) => {
  const out = new Uint8Array(n);
  let v = BigInt(x);
  for (let i = 0; i < n; i++, v >>= 8n) out[i] = Number(v & 0xffn);
  return out;
};
const readLe = (b: Uint8Array, o: number, n: number) => {
  let v = 0n;
  for (let i = n - 1; i >= 0; i--) v = (v << 8n) | BigInt(b[o + i]);
  return v;
};
export const fromHex = (h: string) => Uint8Array.from(h.match(/../g)!.map((x) => parseInt(x, 16)));
export const toHex = (b: Uint8Array) => Array.from(b, (x) => x.toString(16).padStart(2, "0")).join("");
const disc = (name: string) => sha256(enc.encode(`global:${name}`)).subarray(0, 8);

export const gatePda = (scope: bigint | number) =>
  PublicKey.findProgramAddressSync([enc.encode("gate"), le(scope, 8)], PROGRAM_ID)[0];

export const nullifierPda = (gate: PublicKey, nullifier: Uint8Array) =>
  PublicKey.findProgramAddressSync([enc.encode("nullifier"), gate.toBytes(), nullifier], PROGRAM_ID)[0];

export async function fetchGate(conn: Connection, scope: bigint | number): Promise<Gate | null> {
  const acc = await conn.getAccountInfo(gatePda(scope));
  if (!acc) return null;
  const d = acc.data;
  let o = 8;
  const authority = new PublicKey(d.subarray(o, (o += 32)));
  const sc = readLe(d, o, 8); o += 8;
  const minAge = d[o]; o += 1;
  const mask = readLe(d, o, 8); o += 8;
  const n = Number(readLe(d, o, 4)); o += 4;
  const caKeyHashes = Array.from({ length: n }, () => toHex(d.subarray(o, (o += 32))));
  const claimed = readLe(d, o, 8); o += 8;
  o += 1; // bump
  const str = () => {
    const len = Number(readLe(d, o, 4)); o += 4;
    return dec.decode(d.subarray(o, (o += len)));
  };
  const name = str();
  const uri = str();
  const allowedPrefectures = Array.from({ length: 47 }, (_, i) => i + 1).filter((c) => (mask >> BigInt(c - 1)) & 1n);
  return { authority, scope: sc, minAge, allowedPrefectures, caKeyHashes, claimed, name, uri };
}

/** The asset keypair must co-sign. */
export function claimIxs(claimer: PublicKey, asset: PublicKey, scope: bigint | number, c: Claim) {
  const gate = gatePda(scope);
  const nullifier = fromHex(c.public_inputs[1]);
  const data = concat(
    disc("claim"),
    fromHex(c.proof_a),
    fromHex(c.proof_b),
    fromHex(c.proof_c),
    fromHex(c.public_inputs[0]),
    nullifier,
    le(Number(c.current_date), 4),
    le(Number(c.prefecture_code), 1),
    le(BigInt(c.nonce), 8),
  );
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
      data: Buffer.from(data),
    }),
  ];
}

/** Challenge the card signs: SHA-256(binding || nonce_be), split into two 128-bit public inputs. */
export function challengeHalves(binding: Uint8Array, nonce: bigint): [bigint, bigint] {
  const nb = new Uint8Array(8);
  for (let i = 7, v = nonce; i >= 0; i--, v >>= 8n) nb[i] = Number(v & 0xffn);
  const h = sha256(concat(binding, nb));
  const big = (b: Uint8Array) => BigInt("0x" + toHex(b));
  return [big(h.subarray(0, 16)), big(h.subarray(16))];
}

export const PREFECTURES = [
  "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県", "茨城県", "栃木県", "群馬県",
  "埼玉県", "千葉県", "東京都", "神奈川県", "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県",
  "岐阜県", "静岡県", "愛知県", "三重県", "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
  "鳥取県", "島根県", "岡山県", "広島県", "山口県", "徳島県", "香川県", "愛媛県", "高知県", "福岡県",
  "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県",
];

/** Program error code -> message (Anchor custom errors start at 6000). */
export const PROGRAM_ERRORS: Record<number, string> = {
  6000: "Too many CA keys",
  6001: "Invalid prefecture code",
  6002: "Prefecture not allowed by this gate",
  6003: "Untrusted CA",
  6004: "Proof date is stale",
  6005: "Invalid proof",
  6006: "Metadata too long",
};

// BN254 base field modulus (proof A is negated for groth16-solana).
const BN254_P = 21888242871839275222246405745257275088696311157297823662689037894645226208583n
const be32 = (x: string | bigint) => BigInt(x).toString(16).padStart(64, '0')

type SnarkjsProof = { pi_a: string[]; pi_b: string[][]; pi_c: string[] }

/** snarkjs/mopro Groth16 proof JSON -> claim encoding (same as circuits/scripts/export_solana.cjs). */
export function proofToClaim(proof: SnarkjsProof, publicSignals: string[], nonce: string): Claim {
  const [ax, ay] = proof.pi_a
  const [[bx0, bx1], [by0, by1]] = proof.pi_b
  return {
    proof_a: be32(ax) + be32((BN254_P - BigInt(ay)) % BN254_P),
    proof_b: be32(bx1) + be32(bx0) + be32(by1) + be32(by0),
    proof_c: be32(proof.pi_c[0]) + be32(proof.pi_c[1]),
    public_inputs: publicSignals.map(be32),
    nonce,
    current_date: publicSignals[4],
    prefecture_code: publicSignals[6],
  }
}
