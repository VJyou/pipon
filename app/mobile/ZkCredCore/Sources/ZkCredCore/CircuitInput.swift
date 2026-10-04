import Crypto
import Foundation

public enum CircuitInputError: Error, Equatable, CustomStringConvertible {
    /// The certificate does not have the layout the circuit assumes (see docs/research/ios-plan.md).
    case layout(String)
    case tbsTooLarge(padded: Int, max: Int)
    case unknownPrefecture
    case badSignatureLength(Int)

    public var description: String {
        switch self {
        case .layout(let s): return "certificate layout: \(s)"
        case .tbsTooLarge(let p, let m): return "TBS is \(p) bytes after padding, circuit supports \(m)"
        case .unknownPrefecture: return "address does not start with a prefecture name"
        case .badSignatureLength(let n): return "signature is \(n) bytes, expected 256"
        }
    }
}

/// Where the circuit's fields sit in a JPKI signing certificate. Sizes and offsets only —
/// safe to log while checking a real card (no personal values).
public struct CertificateLayout: Equatable, CustomStringConvertible {
    public let tbsLength: Int
    public let tbsPaddedLength: Int
    public let modulusOffset: Int
    public let dobOidOffset: Int
    public let addrOidOffset: Int
    public let addrLongForm: Bool
    public let addrByteLength: Int

    public var description: String {
        "tbs=\(tbsLength)B padded=\(tbsPaddedLength)B mod@\(modulusOffset) dobOid@\(dobOidOffset) "
            + "addrOid@\(addrOidOffset) addrLong=\(addrLongForm) addrBytes=\(addrByteLength)"
    }
}

/// What the holder can prove from the certificate (computed locally, never sent).
public struct HolderFacts: Equatable {
    /// YYYYMMDD (Gregorian)
    public let dateOfBirth: Int
    /// JIS X 0401 code 1...47
    public let prefectureCode: Int

    public func age(on yyyymmdd: Int) -> Int { (yyyymmdd - dateOfBirth) / 10_000 }
}

/// Builds the JSON input of circuits/src/jpki_age_region.circom from a JPKI signing certificate.
/// Mirrors circuits/scripts/gen_dummy_jpki.py.
public struct CircuitInput {
    public static let n = 121
    public static let k = 17
    public static let maxTbsLength = 2048

    public let layout: CertificateLayout
    public let facts: HolderFacts
    let tbsPadded: [UInt8]
    let caSignature: [UInt8]

    static func jpkiOid(_ last: UInt8) -> [UInt8] {
        [0x06, 0x0A, 0x2A, 0x83, 0x08, 0x8C, 0x9B, 0x55, 0x08, 0x05, 0x05, last]
    }

    public init(certificateDER: [UInt8]) throws {
        let parts = try X509Parts(der: certificateDER)
        let tbs = parts.tbs
        caSignature = parts.signature
        guard caSignature.count == 256 else { throw CircuitInputError.badSignatureLength(caSignature.count) }

        // Subject key: 30 82 01 0a 02 82 01 01 00 <256> 02 03 01 00 01
        let modHeader: [UInt8] = [0x30, 0x82, 0x01, 0x0A, 0x02, 0x82, 0x01, 0x01, 0x00]
        guard let modRange = tbs.firstRange(of: modHeader) else {
            throw CircuitInputError.layout("RSA-2048 subject key header not found")
        }
        let modOffset = modRange.upperBound
        guard modOffset + 261 <= tbs.count,
              Array(tbs[(modOffset + 256)..<(modOffset + 261)]) == [0x02, 0x03, 0x01, 0x00, 0x01]
        else { throw CircuitInputError.layout("public exponent is not 65537") }

        // Date of birth: OID(.4) a0 0b 0c 09 'E' YYYYMMDD
        guard let dobOid = tbs.firstRange(of: Self.jpkiOid(4))?.lowerBound else {
            throw CircuitInputError.layout("date-of-birth OID not found")
        }
        guard dobOid + 25 <= tbs.count,
              Array(tbs[(dobOid + 12)..<(dobOid + 16)]) == [0xA0, 0x0B, 0x0C, 0x09]
        else { throw CircuitInputError.layout("date of birth is not a 9-char UTF8String") }
        let digits = tbs[(dobOid + 16)..<(dobOid + 25)]
        guard digits.allSatisfy({ (0x30...0x39).contains($0) }) else {
            throw CircuitInputError.layout("date of birth is not numeric")
        }
        let dob = digits.dropFirst().reduce(0) { $0 * 10 + Int($1 - 0x30) }

        // Address: OID(.5) a0 L 0c L <value>  |  OID(.5) a0 81 L 0c 81 L <value>
        guard let addrOid = tbs.firstRange(of: Self.jpkiOid(5))?.lowerBound, addrOid + 30 <= tbs.count else {
            throw CircuitInputError.layout("address OID not found")
        }
        let h = Array(tbs[(addrOid + 12)..<(addrOid + 18)])
        let longForm: Bool
        let addrLen: Int
        let valueStart: Int
        if h[0] == 0xA0, h[1] < 0x80, h[2] == 0x0C, h[3] < 0x80 {
            longForm = false; addrLen = Int(h[3]); valueStart = addrOid + 16
        } else if h[0] == 0xA0, h[1] == 0x81, h[3] == 0x0C, h[4] == 0x81 {
            longForm = true; addrLen = Int(h[5]); valueStart = addrOid + 18
        } else {
            throw CircuitInputError.layout("address encoding not supported (header \(h.map { String(format: "%02x", $0) }.joined()))")
        }
        guard valueStart + addrLen <= tbs.count else { throw CircuitInputError.layout("address truncated") }
        let address = Array(tbs[valueStart..<(valueStart + addrLen)])
        guard let code = Prefectures.code(forAddressPrefix: address) else { throw CircuitInputError.unknownPrefecture }

        let padded = Self.sha256Pad(tbs)
        guard padded.count <= Self.maxTbsLength else {
            throw CircuitInputError.tbsTooLarge(padded: padded.count, max: Self.maxTbsLength)
        }
        tbsPadded = padded
        layout = CertificateLayout(
            tbsLength: tbs.count, tbsPaddedLength: padded.count, modulusOffset: modOffset,
            dobOidOffset: dobOid, addrOidOffset: addrOid, addrLongForm: longForm, addrByteLength: addrLen)
        facts = HolderFacts(dateOfBirth: dob, prefectureCode: code)
    }

    /// The message the card signs: SHA-256(binding || nonce_be). `binding` is the wallet pubkey or a session id.
    public static func challengeMessage(binding: [UInt8], nonce: UInt64) -> [UInt8] {
        let nonceBE = (0..<8).map { UInt8(truncatingIfNeeded: nonce >> (56 - 8 * $0)) }
        return Array(SHA256.hash(data: binding + nonceBE))
    }

    /// Circuit input as a flat JSON object of decimal strings (mopro / snarkjs format).
    public func json(
        caModulus: [UInt8], challengeMessage msg: [UInt8], challengeSignature: [UInt8],
        currentDate: Int, ageThreshold: Int, scope: UInt64
    ) throws -> [String: Any] {
        guard challengeSignature.count == 256 else { throw CircuitInputError.badSignatureLength(challengeSignature.count) }
        precondition(msg.count == 32 && caModulus.count == 256)
        let tbsField = tbsPadded + [UInt8](repeating: 0, count: Self.maxTbsLength - tbsPadded.count)
        return [
            "tbs": tbsField.map { String($0) },
            "tbsPaddedLen": String(layout.tbsPaddedLength),
            "caSig": Self.limbs(caSignature),
            "caModulus": Self.limbs(caModulus),
            "modOffset": String(layout.modulusOffset),
            "dobOidOffset": String(layout.dobOidOffset),
            "addrOidOffset": String(layout.addrOidOffset),
            "addrLongForm": layout.addrLongForm ? "1" : "0",
            "chalSig": Self.limbs(challengeSignature),
            "chalMsg": [Self.decimal(msg[0..<16]), Self.decimal(msg[16..<32])],
            "currentDate": String(currentDate),
            "ageThreshold": String(ageThreshold),
            "prefectureCode": String(facts.prefectureCode),
            "scope": String(scope),
        ]
    }

    // MARK: - encoding helpers

    static func sha256Pad(_ msg: [UInt8]) -> [UInt8] {
        var p = msg + [0x80]
        while p.count % 64 != 56 { p.append(0) }
        let bits = UInt64(msg.count) * 8
        p += (0..<8).map { UInt8(truncatingIfNeeded: bits >> (56 - 8 * $0)) }
        return p
    }

    /// Big-endian bytes -> k little-endian n-bit limbs as decimal strings.
    static func limbs(_ be: [UInt8]) -> [String] {
        let le = Array(be.reversed())
        func bit(_ i: Int) -> UInt128 { i / 8 < le.count ? UInt128((le[i / 8] >> (i % 8)) & 1) : 0 }
        return (0..<k).map { c in
            var v: UInt128 = 0
            for j in stride(from: n - 1, through: 0, by: -1) { v = (v << 1) | bit(c * n + j) }
            return String(v)
        }
    }

    static func decimal(_ be: ArraySlice<UInt8>) -> String {
        String(be.reduce(UInt128(0)) { ($0 << 8) | UInt128($1) })
    }
}
