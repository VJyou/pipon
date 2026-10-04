use anchor_lang::prelude::*;

#[constant]
pub const GATE_SEED: &[u8] = b"gate";

#[constant]
pub const NULLIFIER_SEED: &[u8] = b"nullifier";

/// Accepted CA keys per gate (J-LIS rotates the signing CA roughly every 4 years).
pub const MAX_CA_KEYS: usize = 4;

/// Proofs may carry today's or yesterday's date (JST), so a proof made just before midnight still lands.
pub const DATE_TOLERANCE_DAYS: i64 = 1;

/// JST = UTC+9. JPKI dates of birth are Japanese calendar dates.
pub const JST_OFFSET_SECS: i64 = 9 * 3600;
