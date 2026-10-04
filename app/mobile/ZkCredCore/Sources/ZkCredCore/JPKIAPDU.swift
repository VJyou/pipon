/// ISO 7816 commands for the JPKI application of the My Number Card.
/// EF ids and the signing command follow the open-source readers listed in THIRD_PARTY_NOTICES.md.
public enum JPKIAPDU {
    public static let aid: [UInt8] = [0xD3, 0x92, 0xF0, 0x00, 0x26, 0x01, 0x00, 0x00, 0x00, 0x01]

    public enum EF {
        /// 署名用証明書 (requires the signing password)
        public static let signCertificate: UInt16 = 0x0001
        /// 署名用秘密鍵
        public static let signKey: UInt16 = 0x001A
        /// 署名用パスワード (6–16 chars)
        public static let signPassword: UInt16 = 0x001B
    }

    public static func selectAP() -> [UInt8] { [0x00, 0xA4, 0x04, 0x0C, UInt8(aid.count)] + aid }

    public static func selectEF(_ id: UInt16) -> [UInt8] {
        [0x00, 0xA4, 0x02, 0x0C, 0x02, UInt8(id >> 8), UInt8(id & 0xFF)]
    }

    /// VERIFY against the currently selected PIN EF. Without data it only reports remaining tries (63Cx).
    public static func verify(_ secret: [UInt8]? = nil) -> [UInt8] {
        guard let secret else { return [0x00, 0x20, 0x00, 0x80] }
        return [0x00, 0x20, 0x00, 0x80, UInt8(secret.count)] + secret
    }

    /// READ BINARY of the selected EF; `le` 0 means 256.
    public static func readBinary(offset: Int, le: UInt8) -> [UInt8] {
        [0x00, 0xB0, UInt8((offset >> 8) & 0x7F), UInt8(offset & 0xFF), le]
    }

    /// COMPUTE DIGITAL SIGNATURE with the signing key (P2 = 0x80 | SFI 0x1A).
    /// P1 = 0x03: the card hashes `message` with SHA-256, wraps it in a DigestInfo and signs PKCS#1 v1.5 —
    /// the form the circuit checks.
    public static func signSHA256DigestInfo(_ message: [UInt8]) -> [UInt8] {
        [0x80, 0x2A, 0x03, 0x9A, UInt8(message.count)] + message + [0x00]
    }

    /// Password as the card expects it: uppercase ASCII letters and digits.
    public static func normalizedPassword(_ s: String) -> [UInt8]? {
        let up = Array(s.uppercased().utf8)
        guard (6...16).contains(up.count), up.allSatisfy({ (0x30...0x39).contains($0) || (0x41...0x5A).contains($0) })
        else { return nil }
        return up
    }

    /// Remaining tries from a 63Cx status, if that is what it is.
    public static func remainingTries(sw1: UInt8, sw2: UInt8) -> Int? {
        sw1 == 0x63 && sw2 & 0xF0 == 0xC0 ? Int(sw2 & 0x0F) : nil
    }
}
