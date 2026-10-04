import Foundation
import Testing
@testable import ZkCredCore

/// The fixture is circuits/fixtures/dummy (dummy CA, dummy person) produced by gen_dummy_jpki.py,
/// so the Swift builder must reproduce its input.json exactly.
struct CircuitInputTests {
    func fixture(_ name: String) throws -> [UInt8] {
        let url = try #require(Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: nil))
        return Array(try Data(contentsOf: url))
    }

    @Test func reproducesPythonInput() throws {
        let expected = try #require(
            try JSONSerialization.jsonObject(with: Data(fixture("input.json"))) as? [String: Any])
        let cert = try fixture("user.der")
        let ca = try fixture("ca.der")

        let input = try CircuitInput(certificateDER: cert)
        #expect(input.facts == HolderFacts(dateOfBirth: 19990401, prefectureCode: 13))
        #expect(input.facts.age(on: 20261004) == 27)

        // The fixture was generated for wallet [7;32]'s pubkey and nonce 42; reuse its card signature.
        let chalMsg = try #require(expected["chalMsg"] as? [String])
        let msgHi = try #require(UInt128(chalMsg[0]))
        let msgLo = try #require(UInt128(chalMsg[1]))
        let msg = (0..<16).map { UInt8(truncatingIfNeeded: msgHi >> (120 - 8 * $0)) }
            + (0..<16).map { UInt8(truncatingIfNeeded: msgLo >> (120 - 8 * $0)) }
        let wallet: [UInt8] = Array(hex: "ea4a6c63e29c520abef5507b132ec5f9954776aebebe7b92421eea691446d22c")
        #expect(CircuitInput.challengeMessage(binding: wallet, nonce: 42) == msg)
        let chalSig = try #require(expected["chalSig"] as? [String])
        let sigBytes = Self.bytes(fromLimbs: chalSig)

        let got = try input.json(
            caModulus: try X509Parts.rsaModulus(der: ca), challengeMessage: msg, challengeSignature: sigBytes,
            currentDate: 20261004, ageThreshold: 20, scope: 1)

        for (key, value) in expected {
            #expect(String(describing: got[key]!) == String(describing: value), "field \(key)")
        }
        #expect(got.count == expected.count)
    }

    @Test func challengeMessageMatchesProgram() {
        // zk_gate: SHA-256(claimer || nonce_be); claimer = pubkey of Keypair::new_from_array([7; 32])
        let wallet: [UInt8] = Array(hex: "ea4a6c63e29c520abef5507b132ec5f9954776aebebe7b92421eea691446d22c")
        let msg = CircuitInput.challengeMessage(binding: wallet, nonce: 42)
        #expect(msg.count == 32)
        #expect(CircuitInput.challengeMessage(binding: wallet, nonce: 43) != msg)
    }

    @Test func prefectureTable() {
        #expect(Prefectures.code(forAddressPrefix: Array("東京都千代田区".utf8)) == 13)
        #expect(Prefectures.code(forAddressPrefix: Array("京都府京都市".utf8)) == 26)
        #expect(Prefectures.code(forAddressPrefix: Array("鹿児島県".utf8)) == 46)
        #expect(Prefectures.code(forAddressPrefix: Array("Tokyo".utf8)) == nil)
    }

    @Test func apdus() {
        #expect(JPKIAPDU.selectEF(0x001B) == [0x00, 0xA4, 0x02, 0x0C, 0x02, 0x00, 0x1B])
        #expect(JPKIAPDU.signSHA256DigestInfo([1, 2]) == [0x80, 0x2A, 0x03, 0x9A, 0x02, 1, 2, 0x00])
        #expect(JPKIAPDU.normalizedPassword("abc123") == Array("ABC123".utf8))
        #expect(JPKIAPDU.normalizedPassword("abc12") == nil)
        #expect(JPKIAPDU.remainingTries(sw1: 0x63, sw2: 0xC4) == 4)
        #expect(JPKIAPDU.remainingTries(sw1: 0x90, sw2: 0x00) == nil)
    }

    @Test func issuerSelection() throws {
        let cert = try fixture("user.der")
        let dummyCA = try fixture("ca.der")
        let jlis = try ["signca02.cer", "signca03.cer"].map { try fixture($0) }
        #expect(try TrustAnchors.issuerModulus(of: cert, among: jlis + [dummyCA]) == X509Parts.rsaModulus(der: dummyCA))
        #expect(throws: TrustAnchors.AnchorError.noIssuer) { try TrustAnchors.issuerModulus(of: cert, among: jlis) }
    }

    @Test func challengeSignatureCheck() throws {
        let cert = try fixture("user.der")
        let expected = try #require(
            try JSONSerialization.jsonObject(with: Data(fixture("input.json"))) as? [String: Any])
        let wallet: [UInt8] = Array(hex: "ea4a6c63e29c520abef5507b132ec5f9954776aebebe7b92421eea691446d22c")
        let msg = CircuitInput.challengeMessage(binding: wallet, nonce: 42)
        let sig = Self.bytes(fromLimbs: try #require(expected["chalSig"] as? [String]))
        try TrustAnchors.checkChallenge(certificateDER: cert, message: msg, signature: sig)
        #expect(throws: TrustAnchors.AnchorError.badChallengeSignature) {
            try TrustAnchors.checkChallenge(
                certificateDER: cert, message: CircuitInput.challengeMessage(binding: wallet, nonce: 43), signature: sig)
        }
    }

    @Test func derLength() throws {
        let cert = try fixture("user.der")
        #expect(try DERLength.total(prefix: Array(cert.prefix(4))) == cert.count)
        #expect(try DERLength.total(prefix: [0x30, 0x05]) == 7)
    }

    static func bytes(fromLimbs limbs: [String]) -> [UInt8] {
        // inverse of CircuitInput.limbs for a 2048-bit value
        var bits = [UInt8](repeating: 0, count: 2048)
        for (c, s) in limbs.enumerated() {
            let v = UInt128(s)!
            for j in 0..<CircuitInput.n where c * CircuitInput.n + j < 2048 {
                bits[c * CircuitInput.n + j] = UInt8((v >> j) & 1)
            }
        }
        return (0..<256).map { b in
            (0..<8).reduce(UInt8(0)) { acc, i in acc | (bits[(255 - b) * 8 + i] << i) }
        }
    }
}

extension Array where Element == UInt8 {
    init(hex: String) {
        var out: [UInt8] = []
        var it = hex.makeIterator()
        while let a = it.next(), let b = it.next() { out.append(UInt8(String([a, b]), radix: 16)!) }
        self = out
    }
}
