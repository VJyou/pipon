use anchor_lang::prelude::*;

use crate::MAX_CA_KEYS;

/// One gated drop / service. `scope` is the circuit's public `scope`, so nullifiers differ per gate.
#[account]
#[derive(InitSpace)]
pub struct Gate {
    pub authority: Pubkey,
    pub scope: u64,
    pub min_age: u8,
    /// Bit (code - 1) set = prefecture code allowed (JIS X 0401, 1..=47).
    pub allowed_prefectures: u64,
    #[max_len(MAX_CA_KEYS)]
    pub ca_key_hashes: Vec<[u8; 32]>,
    pub claimed: u64,
    pub bump: u8,
}

/// Exists iff the nullifier was used for this gate: one claim per person per gate.
#[account]
#[derive(InitSpace)]
pub struct NullifierRecord {
    pub gate: Pubkey,
    pub claimer: Pubkey,
    pub prefecture_code: u8,
    pub slot: u64,
}
