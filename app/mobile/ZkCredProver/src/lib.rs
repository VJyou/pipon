#[macro_use]
mod stubs;

mod error;
pub use error::MoproError;

// Initializes the shared UniFFI scaffolding and defines the `MoproError` enum.
#[cfg(not(target_arch = "wasm32"))]
mopro_ffi::app!();
// Skip wasm_setup!() to avoid extern crate alias conflict
// Instead, we import wasm_bindgen directly when needed
#[cfg(all(feature = "wasm", target_arch = "wasm32"))]
use mopro_ffi::prelude::wasm_bindgen;

/// You can also customize the bindings by #[uniffi::export]
/// Reference: https://mozilla.github.io/uniffi-rs/latest/proc_macro/index.html
#[cfg_attr(feature = "uniffi", uniffi::export)]
pub fn mopro_hello_world() -> String {
    "Hello, World!".to_string()
}

#[cfg_attr(
    all(feature = "wasm", target_arch = "wasm32"),
    wasm_bindgen(js_name = "moproWasmHelloWorld")
)]
pub fn mopro_wasm_hello_world() -> String {
    "Hello, World!".to_string()
}

#[cfg(test)]
mod uniffi_tests {
    #[test]
    fn test_mopro_hello_world() {
        assert_eq!(super::mopro_hello_world(), "Hello, World!");
    }
}


// CIRCOM_TEMPLATE
// --- Circom Example of using groth16 proving and verifying circuits ---

// Module containing the Circom circuit logic (Multiplier2)
#[macro_use]
mod circom;
pub use circom::{
    generate_circom_proof, verify_circom_proof, CircomProof, CircomProofResult, ProofLib, G1, G2,
};

mod witness {
    rust_witness::witness!(jpkiageregion);
}

crate::set_circom_circuits! {
    ("jpki_age_region.zkey", circom_prover::witness::WitnessFn::RustWitness(witness::jpkiageregion_witness)),
}

#[cfg(test)]
mod circom_tests {
    use crate::circom::{generate_circom_proof, verify_circom_proof, ProofLib};
    use std::time::Instant;

    const ZKEY_PATH: &str = "../../../circuits/build/jpki_age_region.zkey";
    const INPUT_PATH: &str = "../../../circuits/fixtures/dummy/input.json";

    fn prove_dummy(lib: ProofLib) {
        let inputs = std::fs::read_to_string(INPUT_PATH).unwrap();
        let t = Instant::now();
        let proof = generate_circom_proof(ZKEY_PATH.to_string(), inputs, lib.clone()).unwrap();
        eprintln!("prove {:?}: {:.2?}, public inputs {}", lib, t.elapsed(), proof.inputs.len());
        // snarkjs-format dump for cross-checking: snarkjs groth16 verify vkey.json public.json proof.json
        let p = &proof.proof;
        let snark = format!(
            r#"{{"pi_a":["{}","{}","{}"],"pi_b":[["{}","{}"],["{}","{}"],["{}","{}"]],"pi_c":["{}","{}","{}"],"protocol":"groth16","curve":"bn128"}}"#,
            p.a.x, p.a.y, p.a.z, p.b.x[0], p.b.x[1], p.b.y[0], p.b.y[1], p.b.z[0], p.b.z[1], p.c.x, p.c.y, p.c.z
        );
        std::fs::write("target/dummy_proof.json", snark).unwrap();
        std::fs::write("target/dummy_public.json", format!("[\"{}\"]", proof.inputs.join("\",\""))).unwrap();
        assert!(verify_circom_proof(ZKEY_PATH.to_string(), proof, lib).unwrap());
    }

    #[test]
    #[ignore = "needs circuits/build (928 MB zkey); run with --ignored --nocapture"]
    fn dummy_fixture_rapidsnark() {
        prove_dummy(ProofLib::Rapidsnark);
    }
}


// HALO2_TEMPLATE
halo2_stub!();

// NOIR_TEMPLATE
noir_stub!();

// GNARK_TEMPLATE
gnark_stub!();
