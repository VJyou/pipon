pub mod constants;
pub mod error;
pub mod instructions;
pub mod state;
pub mod vk;

use anchor_lang::prelude::*;

pub use constants::*;
pub use instructions::*;
pub use state::*;

declare_id!("AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK");

/// Gated claim: a Groth16 proof over a JPKI signing certificate shows age >= gate.min_age and
/// residence in an allowed prefecture; a per-gate nullifier PDA allows one claim per person, and
/// each claim mints a Metaplex Core asset to the claimer.
#[program]
pub mod zk_gate {
    use super::*;

    pub fn initialize_gate(
        ctx: Context<InitializeGate>,
        scope: u64,
        min_age: u8,
        allowed_prefectures: u64,
        ca_key_hashes: Vec<[u8; 32]>,
        name: String,
        uri: String,
    ) -> Result<()> {
        initialize_gate::handler(ctx, scope, min_age, allowed_prefectures, ca_key_hashes, name, uri)
    }

    pub fn claim(ctx: Context<Claim>, proof: ClaimProof) -> Result<()> {
        claim::handler(ctx, proof)
    }
}
