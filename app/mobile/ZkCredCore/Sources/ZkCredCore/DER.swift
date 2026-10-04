import Foundation

/// Minimal DER reader: enough to split an X.509 certificate into TBS / algorithm / signature.
struct DERElement {
    let tag: UInt8
    /// Offset of the tag byte within the parent buffer.
    let start: Int
    let headerLength: Int
    let length: Int

    var valueStart: Int { start + headerLength }
    var end: Int { valueStart + length }
}

enum DERError: Error, Equatable {
    case truncated
    case unsupportedLength
    case unexpectedTag(expected: UInt8, got: UInt8)
}

enum DER {
    /// Read the element whose tag byte is at `offset`.
    static func element(_ bytes: [UInt8], at offset: Int) throws -> DERElement {
        guard offset + 2 <= bytes.count else { throw DERError.truncated }
        let tag = bytes[offset]
        let first = bytes[offset + 1]
        var length = 0
        var header = 2
        if first & 0x80 == 0 {
            length = Int(first)
        } else {
            let n = Int(first & 0x7F)
            guard (1...3).contains(n) else { throw DERError.unsupportedLength }
            guard offset + 2 + n <= bytes.count else { throw DERError.truncated }
            for i in 0..<n { length = (length << 8) | Int(bytes[offset + 2 + i]) }
            header += n
        }
        let el = DERElement(tag: tag, start: offset, headerLength: header, length: length)
        guard el.end <= bytes.count else { throw DERError.truncated }
        return el
    }

    /// Total encoded size of the element starting at offset 0, from its first few bytes
    /// (used to know how much to READ BINARY from the card).
    static func totalLength(prefix: [UInt8]) throws -> Int {
        guard prefix.count >= 2 else { throw DERError.truncated }
        let first = prefix[1]
        if first & 0x80 == 0 { return 2 + Int(first) }
        let n = Int(first & 0x7F)
        guard (1...3).contains(n), prefix.count >= 2 + n else { throw DERError.unsupportedLength }
        var length = 0
        for i in 0..<n { length = (length << 8) | Int(prefix[2 + i]) }
        return 2 + n + length
    }
}

/// An X.509 certificate split into the pieces the circuit needs.
public struct X509Parts {
    /// DER of TBSCertificate (what the CA signed).
    public let tbs: [UInt8]
    /// CA signature value (RSA-2048: 256 bytes).
    public let signature: [UInt8]

    public init(der: [UInt8]) throws {
        let cert = try DER.element(der, at: 0)
        guard cert.tag == 0x30 else { throw DERError.unexpectedTag(expected: 0x30, got: cert.tag) }
        let tbsEl = try DER.element(der, at: cert.valueStart)
        guard tbsEl.tag == 0x30 else { throw DERError.unexpectedTag(expected: 0x30, got: tbsEl.tag) }
        let algEl = try DER.element(der, at: tbsEl.end)
        let sigEl = try DER.element(der, at: algEl.end)
        guard sigEl.tag == 0x03 else { throw DERError.unexpectedTag(expected: 0x03, got: sigEl.tag) }
        tbs = Array(der[tbsEl.start..<tbsEl.end])
        // BIT STRING: first content byte = number of unused bits (0)
        signature = Array(der[(sigEl.valueStart + 1)..<sigEl.end])
    }

    /// RSA modulus (big-endian, leading zero stripped) of a certificate's SubjectPublicKeyInfo.
    public static func rsaModulus(der: [UInt8]) throws -> [UInt8] {
        let header: [UInt8] = [0x30, 0x82, 0x01, 0x0A, 0x02, 0x82, 0x01, 0x01, 0x00]
        guard let at = der.firstRange(of: header)?.upperBound, at + 256 <= der.count else {
            throw CircuitInputError.layout("RSA-2048 public key not found")
        }
        return Array(der[at..<(at + 256)])
    }
}

/// Public entry point for readers: total DER size from the first bytes of an EF.
public enum DERLength {
    public static func total(prefix: [UInt8]) throws -> Int { try DER.totalLength(prefix: prefix) }
}
