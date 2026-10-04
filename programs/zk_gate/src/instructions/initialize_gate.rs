use anchor_lang::prelude::*;

use crate::{error::ErrorCode, Gate, GATE_SEED, MAX_CA_KEYS, MAX_NAME_LEN, MAX_URI_LEN};

#[derive(Accounts)]
#[instruction(scope: u64)]
pub struct InitializeGate<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    #[account(
        init,
        payer = authority,
        space = 8 + Gate::INIT_SPACE,
        seeds = [GATE_SEED, &scope.to_le_bytes()],
        bump,
    )]
    pub gate: Account<'info, Gate>,
    pub system_program: Program<'info, System>,
}

pub fn handler(
    ctx: Context<InitializeGate>,
    scope: u64,
    min_age: u8,
    allowed_prefectures: u64,
    ca_key_hashes: Vec<[u8; 32]>,
    name: String,
    uri: String,
) -> Result<()> {
    require!(ca_key_hashes.len() <= MAX_CA_KEYS, ErrorCode::TooManyCaKeys);
    require!(
        name.len() <= MAX_NAME_LEN && uri.len() <= MAX_URI_LEN,
        ErrorCode::MetadataTooLong
    );
    require!(allowed_prefectures >> 47 == 0, ErrorCode::InvalidPrefecture);

    let gate = &mut ctx.accounts.gate;
    gate.authority = ctx.accounts.authority.key();
    gate.scope = scope;
    gate.min_age = min_age;
    gate.allowed_prefectures = allowed_prefectures;
    gate.ca_key_hashes = ca_key_hashes;
    gate.claimed = 0;
    gate.bump = ctx.bumps.gate;
    gate.name = name;
    gate.uri = uri;
    Ok(())
}
