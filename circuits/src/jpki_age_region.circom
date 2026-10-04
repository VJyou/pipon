pragma circom 2.1.6;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/poseidon.circom";
include "@zk-email/circuits/lib/sha.circom";
include "@zk-email/circuits/lib/rsa.circom";
include "@zk-email/circuits/utils/array.circom";
include "@zk-email/circuits/utils/hash.circom";
include "./gen/prefectures.circom";

// SHA-256 output bits (MSB first) -> k little-endian n-bit chunks, as RSAVerifier65537 expects.
template ShaBitsToChunks(n, k) {
    signal input bits[256];
    signal output out[k];
    var used = (256 + n - 1) \ n;
    component b2n[used];
    for (var i = 0; i < used; i++) {
        b2n[i] = Bits2Num(n);
    }
    for (var i = 0; i < n * used; i++) {
        if (i < 256) {
            b2n[i \ n].in[i % n] <== bits[255 - i];
        } else {
            b2n[i \ n].in[i % n] <== 0;
        }
    }
    for (var i = 0; i < k; i++) {
        if (i < used) {
            out[i] <== b2n[i].out;
        } else {
            out[i] <== 0;
        }
    }
}

// Big-endian bytes (2048-bit integer) -> k little-endian n-bit chunks.
template BytesToChunks(nBytes, n, k) {
    signal input in[nBytes];
    signal output out[k];
    component n2b[nBytes];
    signal bits[nBytes * 8];
    for (var i = 0; i < nBytes; i++) {
        n2b[i] = Num2Bits(8);
        n2b[i].in <== in[nBytes - 1 - i];
        for (var j = 0; j < 8; j++) {
            bits[i * 8 + j] <== n2b[i].out[j];
        }
    }
    component b2n[k];
    for (var c = 0; c < k; c++) {
        b2n[c] = Bits2Num(n);
        for (var j = 0; j < n; j++) {
            var idx = c * n + j;
            if (idx < nBytes * 8) {
                b2n[c].in[j] <== bits[idx];
            } else {
                b2n[c].in[j] <== 0;
            }
        }
        out[c] <== b2n[c].out;
    }
}

// ASCII digit -> value, constrained to 0..9.
template Digit() {
    signal input in;
    signal output out;
    out <== in - 48;
    component lt = LessThan(8);
    lt.in[0] <== out;
    lt.in[1] <== 10;
    lt.out === 1;
}

// DER bytes of OID 1.2.392.200149.8.5.5.<last>, with tag and length (12 bytes).
function JPKI_OID(last) {
    return [0x06, 0x0a, 0x2a, 0x83, 0x08, 0x8c, 0x9b, 0x55, 0x08, 0x05, 0x05, last];
}

// Proves, from a JPKI-style signing certificate and a fresh card signature:
//   - the certificate is signed by the CA whose key hashes to caKeyHash
//   - holder age >= ageThreshold at currentDate
//   - address starts with the prefecture named by prefectureCode
//   - the certificate's key signed chalMsg (binds the proof to a wallet/nonce)
// and outputs a per-scope nullifier.
template JpkiAgeRegion(maxTbsLen, n, k) {
    // ---- private ----
    signal input tbs[maxTbsLen];
    signal input tbsPaddedLen;
    signal input caSig[k];
    signal input caModulus[k];
    signal input modOffset;
    signal input dobOidOffset;
    signal input addrOidOffset;
    signal input addrLongForm;
    signal input chalSig[k];
    // ---- public ----
    signal input chalMsg[2];          // 32-byte message as two big-endian 128-bit halves
    signal input currentDate;         // YYYYMMDD
    signal input ageThreshold;
    signal input prefectureCode;      // 1..47
    signal input scope;
    signal output caKeyHash;
    signal output nullifier;

    var lenBits = log2Ceil(maxTbsLen) + 1;

    // 1. CA signature over TBSCertificate
    component tbsSha = Sha256Bytes(maxTbsLen);
    tbsSha.paddedIn <== tbs;
    tbsSha.paddedInLength <== tbsPaddedLen;
    component tbsHash = ShaBitsToChunks(n, k);
    tbsHash.bits <== tbsSha.out;
    component caVerify = RSAVerifier65537(n, k);
    caVerify.message <== tbsHash.out;
    caVerify.signature <== caSig;
    caVerify.modulus <== caModulus;

    // Fields must lie inside the hashed data (bytes past tbsPaddedLen are unconstrained).
    component inMod = LessEqThan(lenBits);
    inMod.in[0] <== modOffset + 256 + 5;
    inMod.in[1] <== tbsPaddedLen;
    inMod.out === 1;
    component inDob = LessEqThan(lenBits);
    inDob.in[0] <== dobOidOffset + 25;
    inDob.in[1] <== tbsPaddedLen;
    inDob.out === 1;
    component inAddr = LessEqThan(lenBits);
    inAddr.in[0] <== addrOidOffset + 30;
    inAddr.in[1] <== tbsPaddedLen;
    inAddr.out === 1;

    // 2. Subject RSA modulus: 30 82 01 0a 02 82 01 01 00 <256 bytes> 02 03 01 00 01
    component modSel = VarShiftLeft(maxTbsLen, 270);
    modSel.in <== tbs;
    modSel.shift <== modOffset - 9;
    var modHdr[9] = [0x30, 0x82, 0x01, 0x0a, 0x02, 0x82, 0x01, 0x01, 0x00];
    var modTrl[5] = [0x02, 0x03, 0x01, 0x00, 0x01];
    for (var i = 0; i < 9; i++) {
        modSel.out[i] === modHdr[i];
    }
    for (var i = 0; i < 5; i++) {
        modSel.out[265 + i] === modTrl[i];
    }
    component userMod = BytesToChunks(256, n, k);
    for (var i = 0; i < 256; i++) {
        userMod.in[i] <== modSel.out[9 + i];
    }

    // 3. Date of birth: OID(.4) a0 0b 0c 09 'E' 'YYYYMMDD'
    component dobSel = VarShiftLeft(maxTbsLen, 25);
    dobSel.in <== tbs;
    dobSel.shift <== dobOidOffset;
    var dobOid[12] = JPKI_OID(4);
    for (var i = 0; i < 12; i++) {
        dobSel.out[i] === dobOid[i];
    }
    dobSel.out[12] === 0xa0;
    dobSel.out[13] === 0x0b;
    dobSel.out[14] === 0x0c;
    dobSel.out[15] === 0x09;
    component d[9];
    for (var i = 0; i < 9; i++) {
        d[i] = Digit();
        d[i].in <== dobSel.out[16 + i];
    }
    // d[0] is the era digit; YYYYMMDD follows (assumed Gregorian, see docs/research/rsa-spike.md).
    signal dob;
    dob <== d[1].out * 10000000 + d[2].out * 1000000 + d[3].out * 100000 + d[4].out * 10000
          + d[5].out * 1000 + d[6].out * 100 + d[7].out * 10 + d[8].out;
    component ageOk = LessEqThan(32);
    ageOk.in[0] <== dob + ageThreshold * 10000;
    ageOk.in[1] <== currentDate;
    ageOk.out === 1;

    // 4. Address prefix = prefecture name.
    //    short form: OID(.5) a0 L 0c L <value>          (value at +16)
    //    long form : OID(.5) a0 81 L 0c 81 L <value>    (value at +18)
    component addrSel = VarShiftLeft(maxTbsLen, 30);
    addrSel.in <== tbs;
    addrSel.shift <== addrOidOffset;
    var addrOid[12] = JPKI_OID(5);
    for (var i = 0; i < 12; i++) {
        addrSel.out[i] === addrOid[i];
    }
    addrLongForm * (addrLongForm - 1) === 0;
    addrSel.out[12] === 0xa0;
    // short: out[14] == 0x0c ; long: out[13] == 0x81, out[15] == 0x0c, out[16] == 0x81
    (1 - addrLongForm) * (addrSel.out[14] - 0x0c) === 0;
    addrLongForm * (addrSel.out[13] - 0x81) === 0;
    addrLongForm * (addrSel.out[15] - 0x0c) === 0;
    addrLongForm * (addrSel.out[16] - 0x81) === 0;
    signal addrVal[12];
    for (var j = 0; j < 12; j++) {
        addrVal[j] <== addrSel.out[16 + j] + addrLongForm * (addrSel.out[18 + j] - addrSel.out[16 + j]);
    }

    var prefBytes[47][12] = PREF_BYTES();
    var prefLen[47] = PREF_LEN();
    component isCode[47];
    signal sel[47][13];
    var selSum = 0;
    for (var p = 0; p < 47; p++) {
        isCode[p] = IsEqual();
        isCode[p].in[0] <== prefectureCode;
        isCode[p].in[1] <== p + 1;
        selSum += isCode[p].out;
        // compare only the first prefLen[p] bytes
        for (var j = 0; j < 12; j++) {
            if (j < prefLen[p]) {
                sel[p][j] <== isCode[p].out * (addrVal[j] - prefBytes[p][j]);
                sel[p][j] === 0;
            } else {
                sel[p][j] <== 0;
            }
        }
        sel[p][12] <== 0;
    }
    selSum === 1;

    // 5. Card key signed chalMsg (PKCS#1 v1.5 / SHA-256, as JPKI cards do).
    component msgBits[2];
    signal msgBytes[32];
    for (var h = 0; h < 2; h++) {
        msgBits[h] = Num2Bits(128);
        msgBits[h].in <== chalMsg[h];
        for (var b = 0; b < 16; b++) {
            var acc = 0;
            for (var j = 0; j < 8; j++) {
                acc += msgBits[h].out[(15 - b) * 8 + j] * (1 << j);
            }
            msgBytes[h * 16 + b] <== acc;
        }
    }
    component chalSha = Sha256Bytes(64);
    for (var i = 0; i < 32; i++) {
        chalSha.paddedIn[i] <== msgBytes[i];
    }
    chalSha.paddedIn[32] <== 0x80;
    for (var i = 33; i < 62; i++) {
        chalSha.paddedIn[i] <== 0;
    }
    chalSha.paddedIn[62] <== 0x01;   // bit length 256 = 0x0100
    chalSha.paddedIn[63] <== 0x00;
    chalSha.paddedInLength <== 64;
    component chalHash = ShaBitsToChunks(n, k);
    chalHash.bits <== chalSha.out;
    component chalVerify = RSAVerifier65537(n, k);
    chalVerify.message <== chalHash.out;
    chalVerify.signature <== chalSig;
    chalVerify.modulus <== userMod.out;

    // 6. Outputs
    caKeyHash <== PoseidonLarge(n, k)(caModulus);
    signal sigHash <== PoseidonLarge(n, k)(caSig);
    nullifier <== Poseidon(2)([sigHash, scope]);
}

component main { public [chalMsg, currentDate, ageThreshold, prefectureCode, scope] } = JpkiAgeRegion(2048, 121, 17);
