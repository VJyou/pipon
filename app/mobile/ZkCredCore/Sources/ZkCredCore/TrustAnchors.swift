import Crypto
import CryptoExtras

/// Picks the CA that signed a certificate and pre-checks signatures before spending seconds on a proof.
public enum TrustAnchors {
    public enum AnchorError: Error, Equatable {
        case noIssuer
        case badChallengeSignature
    }

    static func publicKey(modulus: [UInt8]) throws -> _RSA.Signing.PublicKey {
        try _RSA.Signing.PublicKey(n: modulus, e: [0x01, 0x00, 0x01])
    }

    static func verify(modulus: [UInt8], signature: [UInt8], message: [UInt8]) -> Bool {
        guard let key = try? publicKey(modulus: modulus) else { return false }
        return key.isValidSignature(
            _RSA.Signing.RSASignature(rawRepresentation: signature), for: SHA256.hash(data: message),
            padding: .insecurePKCS1v1_5)
    }

    /// RSA modulus of the CA (among `caCertificates`, DER) whose key verifies `certificateDER`'s signature.
    public static func issuerModulus(of certificateDER: [UInt8], among caCertificates: [[UInt8]]) throws -> [UInt8] {
        let parts = try X509Parts(der: certificateDER)
        for ca in caCertificates {
            let modulus = try X509Parts.rsaModulus(der: ca)
            if verify(modulus: modulus, signature: parts.signature, message: parts.tbs) { return modulus }
        }
        throw AnchorError.noIssuer
    }

    /// The card's signature over the challenge must verify under the certificate's own key (PKCS#1 v1.5, SHA-256).
    public static func checkChallenge(certificateDER: [UInt8], message: [UInt8], signature: [UInt8]) throws {
        let parts = try X509Parts(der: certificateDER)
        let modulus = try X509Parts.rsaModulus(der: parts.tbs)
        guard verify(modulus: modulus, signature: signature, message: message) else {
            throw AnchorError.badChallengeSignature
        }
    }
}
