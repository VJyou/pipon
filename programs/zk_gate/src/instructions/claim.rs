use anchor_lang::prelude::*;
use groth16_solana::groth16::Groth16Verifier;

use crate::{
    error::ErrorCode, vk::VERIFYINGKEY, Gate, NullifierRecord, DATE_TOLERANCE_DAYS, JST_OFFSET_SECS,
    NULLIFIER_SEED,
};

#[derive(Accounts)]
#[instruction(proof: ClaimProof)]
pub struct Claim<'info> {
    #[account(mut)]
    pub claimer: Signer<'info>,
    #[account(mut)]
    pub gate: Account<'info, Gate>,
    // `init` fails if the record exists: this is the one-claim-per-person check.
    #[account(
        init,
        payer = claimer,
        space = 8 + NullifierRecord::INIT_SPACE,
        seeds = [NULLIFIER_SEED, gate.key().as_ref(), proof.nullifier.as_ref()],
        bump,
    )]
    pub nullifier_record: Account<'info, NullifierRecord>,
    pub system_program: Program<'info, System>,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct ClaimProof {
    /// Proof A, already negated (groth16-solana convention).
    pub proof_a: [u8; 64],
    pub proof_b: [u8; 128],
    pub proof_c: [u8; 64],
    pub ca_key_hash: [u8; 32],
    pub nullifier: [u8; 32],
    /// YYYYMMDD (JST) the proof was made for.
    pub current_date: u32,
    pub prefecture_code: u8,
    /// Challenge the card signed is SHA-256(claimer || nonce_be).
    pub nonce: u64,
}

pub fn handler(ctx: Context<Claim>, proof: ClaimProof) -> Result<()> {
    let gate = &ctx.accounts.gate;
    let claimer = ctx.accounts.claimer.key();

    require!((1..=47).contains(&proof.prefecture_code), ErrorCode::InvalidPrefecture);
    require!(
        gate.allowed_prefectures >> (proof.prefecture_code - 1) & 1 == 1,
        ErrorCode::PrefectureNotAllowed
    );
    require!(gate.ca_key_hashes.contains(&proof.ca_key_hash), ErrorCode::UntrustedCa);

    let now = Clock::get()?.unix_timestamp;
    let fresh = (0..=DATE_TOLERANCE_DAYS)
        .any(|d| jst_yyyymmdd(now - d * 86_400) == proof.current_date);
    require!(fresh, ErrorCode::StaleDate);

    // The program rebuilds every public input except the two circuit outputs, so a proof
    // only verifies for this claimer, this gate, and the gate's age threshold.
    let chal = solana_sha256_hasher::hashv(&[claimer.as_ref(), &proof.nonce.to_be_bytes()]).to_bytes();
    let mut chal_hi = [0u8; 32];
    let mut chal_lo = [0u8; 32];
    chal_hi[16..].copy_from_slice(&chal[..16]);
    chal_lo[16..].copy_from_slice(&chal[16..]);

    let public_inputs: [[u8; 32]; 8] = [
        proof.ca_key_hash,
        proof.nullifier,
        chal_hi,
        chal_lo,
        be32(proof.current_date as u64),
        be32(gate.min_age as u64),
        be32(proof.prefecture_code as u64),
        be32(gate.scope),
    ];
    let mut verifier = Groth16Verifier::new(
        &proof.proof_a,
        &proof.proof_b,
        &proof.proof_c,
        &public_inputs,
        &VERIFYINGKEY,
    )
    .map_err(|_| ErrorCode::InvalidProof)?;
    verifier.verify().map_err(|_| ErrorCode::InvalidProof)?;

    let record = &mut ctx.accounts.nullifier_record;
    record.gate = gate.key();
    record.claimer = claimer;
    record.prefecture_code = proof.prefecture_code;
    record.slot = Clock::get()?.slot;
    ctx.accounts.gate.claimed += 1;

    emit!(Claimed {
        gate: record.gate,
        claimer,
        prefecture_code: proof.prefecture_code,
    });
    Ok(())
}

#[event]
pub struct Claimed {
    pub gate: Pubkey,
    pub claimer: Pubkey,
    pub prefecture_code: u8,
}

fn be32(x: u64) -> [u8; 32] {
    let mut out = [0u8; 32];
    out[24..].copy_from_slice(&x.to_be_bytes());
    out
}

/// Unix seconds -> YYYYMMDD in JST (civil-from-days, H. Hinnant).
pub fn jst_yyyymmdd(unix: i64) -> u32 {
    let z = (unix + JST_OFFSET_SECS).div_euclid(86_400) + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = yoe + era * 400 + if m <= 2 { 1 } else { 0 };
    (y * 10_000 + m * 100 + d) as u32
}

#[cfg(test)]
mod tests {
    use super::jst_yyyymmdd;

    #[test]
    fn jst_dates() {
        assert_eq!(jst_yyyymmdd(0), 19700101); // 09:00 JST
        assert_eq!(jst_yyyymmdd(1_791_039_600), 20261004); // 2026-10-03T15:00Z = 10/04 00:00 JST
        assert_eq!(jst_yyyymmdd(1_791_039_599), 20261003);
        assert_eq!(jst_yyyymmdd(951_782_400), 20000229); // 2000-02-29T00:00Z
    }
}
