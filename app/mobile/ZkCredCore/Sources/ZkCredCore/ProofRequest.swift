import Foundation

/// A request handed over by the web demo: `zkcred://prove?s=<relay session URL>`.
/// GET <session URL> returns `{ request: ProofRequest }`; POST <session URL>/result takes `ProofResult`.
public struct ProofRequest: Codable, Equatable, Sendable {
    /// Wallet pubkey (base58) or a 32-byte hex session id the card's signature is bound to.
    public let binding: String
    /// Service id; the nullifier is unique per (card, scope).
    public let scope: UInt64
    public let service: String
    public let statement: [String]

    /// 32 bytes the challenge is built from.
    public func bindingBytes() throws -> [UInt8] {
        if binding.count == 64, let hex = [UInt8](hexString: binding) { return hex }
        guard let raw = Base58.decode(binding), raw.count == 32 else { throw RequestError.badBinding }
        return raw
    }

    public enum RequestError: Error, Equatable {
        case badLink
        case badBinding
    }

    /// Relay session URL from the deep link.
    public static func sessionURL(fromDeepLink link: String) throws -> URL {
        guard let comps = URLComponents(string: link), comps.scheme == "zkcred", comps.host == "prove",
              let s = comps.queryItems?.first(where: { $0.name == "s" })?.value, let url = URL(string: s),
              url.scheme == "http" || url.scheme == "https"
        else { throw RequestError.badLink }
        return url
    }
}

/// What the phone posts back (snarkjs Groth16 JSON, the format the web demo verifies).
public struct ProofResult: Codable, Sendable {
    public struct Proof: Codable, Sendable {
        public let pi_a: [String]
        public let pi_b: [[String]]
        public let pi_c: [String]
        public let `protocol`: String
        public let curve: String

        public init(a: [String], b: [[String]], c: [String]) {
            pi_a = a; pi_b = b; pi_c = c; `protocol` = "groth16"; curve = "bn128"
        }
    }

    public let proof: Proof
    public let publicSignals: [String]
    public let nonce: String

    public init(proof: Proof, publicSignals: [String], nonce: UInt64) {
        self.proof = proof
        self.publicSignals = publicSignals
        self.nonce = String(nonce)
    }
}

public enum Base58 {
    static let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".utf8)

    public static func decode(_ s: String) -> [UInt8]? {
        var bytes: [UInt8] = []
        for c in s.utf8 {
            guard let digit = alphabet.firstIndex(of: c) else { return nil }
            var carry = digit
            for i in bytes.indices.reversed() {
                carry += Int(bytes[i]) * 58
                bytes[i] = UInt8(carry & 0xFF)
                carry >>= 8
            }
            while carry > 0 {
                bytes.insert(UInt8(carry & 0xFF), at: 0)
                carry >>= 8
            }
        }
        let zeros = s.utf8.prefix(while: { $0 == alphabet[0] }).count
        return [UInt8](repeating: 0, count: zeros) + bytes
    }
}

extension [UInt8] {
    init?(hexString s: String) {
        guard s.count % 2 == 0 else { return nil }
        var out: [UInt8] = []
        var i = s.startIndex
        while i < s.endIndex {
            let j = s.index(i, offsetBy: 2)
            guard let b = UInt8(s[i..<j], radix: 16) else { return nil }
            out.append(b)
            i = j
        }
        self = out
    }
}
