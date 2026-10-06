import Crypto
import CryptoExtras

/// Stands in for the card during development: signs the challenge like JPKI's COMPUTE DIGITAL SIGNATURE
/// (PKCS#1 v1.5 over DigestInfo(SHA-256(message))) with a dummy persona key (circuits/build/persona-*.pem).
/// Test keys only; release builds never bundle them.
public enum DevCard {
    public static func sign(_ message: [UInt8], privateKeyPEM: String) throws -> [UInt8] {
        let key = try _RSA.Signing.PrivateKey(pemRepresentation: privateKeyPEM)
        let sig = try key.signature(for: SHA256.hash(data: message), padding: .insecurePKCS1v1_5)
        return Array(sig.rawRepresentation)
    }
}
