fn main() {
    // Transpile the circuit's witness wasm to C (rust-witness). The wasm comes from circuits/build/
    // (not in git; see docs/setup/mac.md). Override the directory with ZKCRED_WASM_DIR.
    println!("cargo:rerun-if-env-changed=ZKCRED_WASM_DIR");
    let dir = std::env::var("ZKCRED_WASM_DIR")
        .unwrap_or_else(|_| "../../../circuits/build/jpki_age_region_js".to_string());
    rust_witness::transpile::transpile_wasm(dir);
}
