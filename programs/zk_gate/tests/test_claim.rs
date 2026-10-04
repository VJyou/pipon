//! End-to-end: a real Groth16 proof (dummy JPKI cert, see circuits/scripts/gen_dummy_jpki.py)
//! verified on-chain in LiteSVM. Fixture: tests/fixtures/claim.json, bound to the [7; 32] keypair.
use {
    anchor_lang::{
        prelude::Pubkey, solana_program::instruction::Instruction, system_program, InstructionData,
        ToAccountMetas,
    },
    litesvm::LiteSVM,
    solana_clock::Clock,
    solana_compute_budget_interface::ComputeBudgetInstruction,
    solana_keypair::Keypair,
    solana_message::{Message, VersionedMessage},
    solana_signer::Signer,
    solana_transaction::versioned::VersionedTransaction,
    zk_gate::{ClaimProof, GATE_SEED, NULLIFIER_SEED},
};

const SCOPE: u64 = 1;
const TOKYO: u8 = 13;
// 2026-10-04 12:00 JST
const NOW: i64 = 1_791_082_800;

struct Fixture {
    proof: ClaimProof,
}

fn hex32<const N: usize>(s: &str) -> [u8; N] {
    hex::decode(s).unwrap().try_into().unwrap()
}

fn load_fixture() -> Fixture {
    let v: serde_json::Value =
        serde_json::from_str(include_str!("fixtures/claim.json")).unwrap();
    let s = |k: &str| v[k].as_str().unwrap().to_string();
    let public: Vec<String> = v["public_inputs"]
        .as_array()
        .unwrap()
        .iter()
        .map(|x| x.as_str().unwrap().to_string())
        .collect();
    Fixture {
        proof: ClaimProof {
            proof_a: hex32(&s("proof_a")),
            proof_b: hex32(&s("proof_b")),
            proof_c: hex32(&s("proof_c")),
            ca_key_hash: hex32(&public[0]),
            nullifier: hex32(&public[1]),
            current_date: s("current_date").parse().unwrap(),
            prefecture_code: s("prefecture_code").parse().unwrap(),
            nonce: s("nonce").parse().unwrap(),
        },
    }
}

fn setup() -> (LiteSVM, Keypair, Keypair) {
    let mut svm = LiteSVM::new();
    svm.add_program(zk_gate::id(), include_bytes!("../../../target/deploy/zk_gate.so"))
        .unwrap();
    // scripts/fetch-programs.sh
    svm.add_program(mpl_core::ID, include_bytes!("fixtures/mpl_core.so")).unwrap();
    let mut clock: Clock = svm.get_sysvar();
    clock.unix_timestamp = NOW;
    svm.set_sysvar(&clock);

    let authority = Keypair::new();
    let claimer = Keypair::new_from_array([7u8; 32]);
    svm.airdrop(&authority.pubkey(), 10_000_000_000).unwrap();
    svm.airdrop(&claimer.pubkey(), 10_000_000_000).unwrap();
    (svm, authority, claimer)
}

fn gate_pda(scope: u64) -> Pubkey {
    Pubkey::find_program_address(&[GATE_SEED, &scope.to_le_bytes()], &zk_gate::id()).0
}

fn send(svm: &mut LiteSVM, signers: &[&Keypair], ixs: &[Instruction]) -> Result<u64, String> {
    svm.expire_blockhash();
    let msg = Message::new_with_blockhash(ixs, Some(&signers[0].pubkey()), &svm.latest_blockhash());
    let tx = VersionedTransaction::try_new(VersionedMessage::Legacy(msg), signers).unwrap();
    svm.send_transaction(tx)
        .map(|m| m.compute_units_consumed)
        .map_err(|e| format!("{:?}\n{}", e.err, e.meta.logs.join("\n")))
}

fn init_gate(svm: &mut LiteSVM, authority: &Keypair, scope: u64, prefectures: u64, ca: [u8; 32]) {
    let ix = Instruction::new_with_bytes(
        zk_gate::id(),
        &zk_gate::instruction::InitializeGate {
            scope,
            min_age: 20,
            allowed_prefectures: prefectures,
            ca_key_hashes: vec![ca],
            name: "zkCredentials Tokyo".into(),
            uri: "https://example.com/zkcred/tokyo.json".into(),
        }
        .data(),
        zk_gate::accounts::InitializeGate {
            authority: authority.pubkey(),
            gate: gate_pda(scope),
            system_program: system_program::ID,
        }
        .to_account_metas(None),
    );
    send(svm, &[authority], &[ix]).unwrap();
}

fn claim_ix(claimer: &Pubkey, asset: &Pubkey, scope: u64, proof: &ClaimProof) -> Vec<Instruction> {
    let gate = gate_pda(scope);
    let record = Pubkey::find_program_address(
        &[NULLIFIER_SEED, gate.as_ref(), proof.nullifier.as_ref()],
        &zk_gate::id(),
    )
    .0;
    vec![
        ComputeBudgetInstruction::set_compute_unit_limit(1_400_000),
        Instruction::new_with_bytes(
            zk_gate::id(),
            &zk_gate::instruction::Claim { proof: proof.clone() }.data(),
            zk_gate::accounts::Claim {
                claimer: *claimer,
                gate,
                nullifier_record: record,
                asset: *asset,
                mpl_core_program: mpl_core::ID,
                system_program: system_program::ID,
            }
            .to_account_metas(None),
        ),
    ]
}

fn claim(svm: &mut LiteSVM, claimer: &Keypair, scope: u64, proof: &ClaimProof) -> Result<u64, String> {
    let asset = Keypair::new();
    let ixs = claim_ix(&claimer.pubkey(), &asset.pubkey(), scope, proof);
    let cu = send(svm, &[claimer, &asset], &ixs)?;
    let acc = svm.get_account(&asset.pubkey()).expect("asset created");
    assert_eq!(acc.owner, mpl_core::ID);
    // BaseAssetV1: key(1) | owner(32) | ...
    assert_eq!(&acc.data[1..33], claimer.pubkey().as_ref(), "asset owned by claimer");
    Ok(cu)
}

#[test]
fn claim_once_then_reject_replay() {
    let f = load_fixture();
    let (mut svm, authority, claimer) = setup();
    init_gate(&mut svm, &authority, SCOPE, 1 << (TOKYO - 1), f.proof.ca_key_hash);

    let cu = claim(&mut svm, &claimer, SCOPE, &f.proof).unwrap();
    println!("claim compute units: {cu}");

    let err = claim(&mut svm, &claimer, SCOPE, &f.proof).unwrap_err();
    assert!(err.contains("already in use"), "replay must hit the existing nullifier PDA: {err}");
}

#[test]
fn reject_proof_from_another_wallet() {
    let f = load_fixture();
    let (mut svm, authority, _) = setup();
    init_gate(&mut svm, &authority, SCOPE, 1 << (TOKYO - 1), f.proof.ca_key_hash);
    let thief = Keypair::new();
    svm.airdrop(&thief.pubkey(), 1_000_000_000).unwrap();

    let err = claim(&mut svm, &thief, SCOPE, &f.proof).unwrap_err();
    assert!(err.contains("InvalidProof"), "{err}");
}

#[test]
fn reject_disallowed_prefecture() {
    let f = load_fixture();
    let (mut svm, authority, claimer) = setup();
    init_gate(&mut svm, &authority, SCOPE, 1 << (27 - 1), f.proof.ca_key_hash); // 大阪府 only

    let err = claim(&mut svm, &claimer, SCOPE, &f.proof).unwrap_err();
    assert!(err.contains("PrefectureNotAllowed"), "{err}");
}

#[test]
fn reject_lying_about_prefecture() {
    let f = load_fixture();
    let (mut svm, authority, claimer) = setup();
    init_gate(&mut svm, &authority, SCOPE, u64::MAX >> 17, f.proof.ca_key_hash); // all 47
    let mut p = f.proof.clone();
    p.prefecture_code = 27;

    let err = claim(&mut svm, &claimer, SCOPE, &p).unwrap_err();
    assert!(err.contains("InvalidProof"), "{err}");
}

#[test]
fn reject_untrusted_ca() {
    let f = load_fixture();
    let (mut svm, authority, claimer) = setup();
    init_gate(&mut svm, &authority, SCOPE, 1 << (TOKYO - 1), [1u8; 32]);

    let err = claim(&mut svm, &claimer, SCOPE, &f.proof).unwrap_err();
    assert!(err.contains("UntrustedCa"), "{err}");
}

#[test]
fn reject_stale_date() {
    let f = load_fixture();
    let (mut svm, authority, claimer) = setup();
    init_gate(&mut svm, &authority, SCOPE, 1 << (TOKYO - 1), f.proof.ca_key_hash);
    let mut clock: Clock = svm.get_sysvar();
    clock.unix_timestamp = NOW + 2 * 86_400;
    svm.set_sysvar(&clock);

    let err = claim(&mut svm, &claimer, SCOPE, &f.proof).unwrap_err();
    assert!(err.contains("StaleDate"), "{err}");
}

#[test]
fn reject_other_scope() {
    // Same person, different gate: the circuit's scope differs, so this proof is invalid there.
    let f = load_fixture();
    let (mut svm, authority, claimer) = setup();
    init_gate(&mut svm, &authority, 2, 1 << (TOKYO - 1), f.proof.ca_key_hash);

    let err = claim(&mut svm, &claimer, 2, &f.proof).unwrap_err();
    assert!(err.contains("InvalidProof"), "{err}");
}
