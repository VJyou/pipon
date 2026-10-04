#if canImport(CoreNFC)
import CoreNFC
import ZkCredCore

/// Reads the JPKI signing certificate and has the card sign a challenge, in one NFC session
/// (the password verification only holds within the session).
/// The certificate stays in memory; nothing is logged or written to disk.
final class JPKIReader: NSObject, NFCTagReaderSessionDelegate, @unchecked Sendable {
    struct Output {
        let certificateDER: [UInt8]
        let challengeSignature: [UInt8]
    }

    enum ReaderError: LocalizedError {
        case nfcUnavailable
        case notMyNumberCard
        case wrongPassword(remaining: Int)
        case passwordLocked
        case card(String, UInt8, UInt8)

        var errorDescription: String? {
            switch self {
            case .nfcUnavailable: return "NFC is not available on this device."
            case .notMyNumberCard: return "This card is not a My Number Card."
            case .wrongPassword(let n): return "Wrong signing password. \(n) tries left before the certificate locks."
            case .passwordLocked: return "The signing password is locked. Reset it at your city office."
            case .card(let step, let sw1, let sw2): return String(format: "Card error at %@ (%02X%02X)", step, sw1, sw2)
            }
        }
    }

    private var session: NFCTagReaderSession?
    private var continuation: CheckedContinuation<Output, Error>?
    private var password: [UInt8] = []
    private var message: [UInt8] = []

    /// - Parameters:
    ///   - password: signing password (6–16 alphanumerics), already normalized with `JPKIAPDU.normalizedPassword`
    ///   - message: the 32-byte challenge, `CircuitInput.challengeMessage(binding:nonce:)`
    func readAndSign(password: [UInt8], message: [UInt8]) async throws -> Output {
        guard NFCTagReaderSession.readingAvailable else { throw ReaderError.nfcUnavailable }
        self.password = password
        self.message = message
        return try await withCheckedThrowingContinuation { cont in
            continuation = cont
            session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
            session?.alertMessage = "Hold your My Number Card against the top of the iPhone."
            session?.begin()
        }
    }

    private func finish(_ result: Result<Output, Error>) {
        password = []
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(with: result)
    }

    // MARK: NFCTagReaderSessionDelegate

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        finish(.failure(error)) // no-op if already finished
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let first = tags.first, case .iso7816(let tag) = first else {
            session.invalidate(errorMessage: ReaderError.notMyNumberCard.localizedDescription)
            return
        }
        Task {
            do {
                try await session.connect(to: first)
                let out = try await run(tag, session: session)
                session.alertMessage = "Done. You can remove the card."
                session.invalidate()
                finish(.success(out))
            } catch {
                session.invalidate(errorMessage: error.localizedDescription)
                finish(.failure(error))
            }
        }
    }

    // MARK: card protocol

    private func send(_ tag: NFCISO7816Tag, _ apdu: [UInt8], step: String, allow: Set<UInt16> = [0x9000]) async throws
        -> (Data, UInt8, UInt8)
    {
        guard let cmd = NFCISO7816APDU(data: Data(apdu)) else { throw ReaderError.card(step, 0, 0) }
        let (data, sw1, sw2) = try await tag.sendCommand(apdu: cmd)
        let sw = UInt16(sw1) << 8 | UInt16(sw2)
        if !allow.contains(sw) && JPKIAPDU.remainingTries(sw1: sw1, sw2: sw2) == nil {
            throw ReaderError.card(step, sw1, sw2)
        }
        return (data, sw1, sw2)
    }

    private func run(_ tag: NFCISO7816Tag, session: NFCTagReaderSession) async throws -> Output {
        _ = try await send(tag, JPKIAPDU.selectAP(), step: "select JPKI")

        // Check remaining tries before spending one.
        _ = try await send(tag, JPKIAPDU.selectEF(JPKIAPDU.EF.signPassword), step: "select password")
        let (_, s1, s2) = try await send(tag, JPKIAPDU.verify(), step: "password status", allow: [0x9000])
        if let left = JPKIAPDU.remainingTries(sw1: s1, sw2: s2), left == 0 { throw ReaderError.passwordLocked }

        session.alertMessage = "Checking password…"
        let (_, v1, v2) = try await send(tag, JPKIAPDU.verify(password), step: "verify password")
        if let left = JPKIAPDU.remainingTries(sw1: v1, sw2: v2) {
            throw left == 0 ? ReaderError.passwordLocked : ReaderError.wrongPassword(remaining: left)
        }

        session.alertMessage = "Reading certificate…"
        _ = try await send(tag, JPKIAPDU.selectEF(JPKIAPDU.EF.signCertificate), step: "select certificate")
        let (head, _, _) = try await send(tag, JPKIAPDU.readBinary(offset: 0, le: 4), step: "read certificate")
        let total = try DERLength.total(prefix: Array(head))
        var cert: [UInt8] = []
        while cert.count < total {
            let want = min(256, total - cert.count)
            let (chunk, _, _) = try await send(
                tag, JPKIAPDU.readBinary(offset: cert.count, le: UInt8(want & 0xFF)), step: "read certificate")
            if chunk.isEmpty { break }
            cert += chunk
        }

        session.alertMessage = "Signing the challenge…"
        let (sig, _, _) = try await send(tag, JPKIAPDU.signSHA256DigestInfo(message), step: "sign")
        return Output(certificateDER: Array(cert.prefix(total)), challengeSignature: Array(sig))
    }
}
#endif
