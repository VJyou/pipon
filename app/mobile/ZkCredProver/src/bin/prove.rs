//! Desktop prover for the macOS backup path (`app/mobile/ZkCredMac`).
//! Reads circuit inputs (JSON) from stdin, proves with rapidsnark and prints
//! `{"proof":{"a":[..],"b":[[..],..],"c":[..]},"publicSignals":[..]}` on stdout.
//! Inputs come through a pipe so the certificate never touches the disk.
//!
//! cargo run --release --bin prove -- <zkey path> < input.json
use std::io::Read;

use ZkCredProver::{generate_circom_proof, ProofLib};

fn main() -> anyhow::Result<()> {
    let zkey = std::env::args().nth(1).ok_or_else(|| anyhow::anyhow!("usage: prove <zkey path> < input.json"))?;
    let mut inputs = String::new();
    std::io::stdin().read_to_string(&mut inputs)?;
    let res = generate_circom_proof(zkey, inputs, ProofLib::Rapidsnark)?;
    let p = &res.proof;
    let out = serde_json::json!({
        "proof": {
            "a": [p.a.x, p.a.y, p.a.z],
            "b": [p.b.x, p.b.y, p.b.z],
            "c": [p.c.x, p.c.y, p.c.z],
        },
        "publicSignals": res.inputs,
    });
    println!("{out}");
    Ok(())
}
