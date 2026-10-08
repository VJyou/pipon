import SwiftUI
import ZkCredCore

/// Reads the holder's own card and shows only what is safe to see while checking the circuit's assumptions
/// (docs/research/ios-plan.md): the certificate layout (sizes/offsets) and whether the card's challenge signature
/// verifies. Never shows, logs or stores the certificate or any personal value.
struct CardCheckView: View {
    @State private var password = ""
    @State private var lines: [String] = []
    @State private var running = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card check (layout only)").font(.headline)
            SecureField("Signing password (6–16 characters)", text: $password)
                .keyboardType(.asciiCapable)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .textFieldStyle(.roundedBorder)
            Button(running ? "Reading…" : "Read card") { run() }
                .buttonStyle(.bordered)
                .disabled(running || JPKIAPDU.normalizedPassword(password) == nil)
            ForEach(lines, id: \.self) { Text($0).font(.system(.footnote, design: .monospaced)) }
        }
    }

    private func run() {
        guard let secret = JPKIAPDU.normalizedPassword(password) else { return }
        password = ""
        running = true
        lines = []
        // A throwaway challenge: all-zero binding, nonce 0. Only used to check the card's signature format.
        let message = CircuitInput.challengeMessage(binding: [UInt8](repeating: 0, count: 32), nonce: 0)
        Task {
            var out: [String] = []
            #if canImport(CoreNFC)
            do {
                let read = try await JPKIReader().readAndSign(password: secret, message: message)
                out.append("certificate: \(read.certificateDER.count) B, signature: \(read.challengeSignature.count) B")
                do {
                    try TrustAnchors.checkChallenge(
                        certificateDER: read.certificateDER, message: message, signature: read.challengeSignature)
                    out.append("challenge signature: OK (PKCS#1 v1.5, SHA-256)")
                } catch {
                    out.append("challenge signature: FAILED (\(error))")
                }
                do {
                    let input = try CircuitInput(certificateDER: read.certificateDER)
                    out.append("layout: \(input.layout)")
                } catch {
                    out.append("layout: FAILED (\(error))")
                }
            } catch {
                out.append("read: \(error.localizedDescription)")
            }
            #else
            out.append("NFC is not available on this platform.")
            #endif
            lines = out
            running = false
        }
    }
}
