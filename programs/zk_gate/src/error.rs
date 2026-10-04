use anchor_lang::prelude::*;

#[error_code]
pub enum ErrorCode {
    #[msg("Too many CA keys")]
    TooManyCaKeys,
    #[msg("Prefecture code must be 1..=47")]
    InvalidPrefecture,
    #[msg("Prefecture is not allowed by this gate")]
    PrefectureNotAllowed,
    #[msg("CA key is not trusted by this gate")]
    UntrustedCa,
    #[msg("Proof date is not today or yesterday (JST)")]
    StaleDate,
    #[msg("Groth16 proof verification failed")]
    InvalidProof,
    #[msg("Name or URI too long")]
    MetadataTooLong,
}
