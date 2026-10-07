import CryptoTokenKit
import Foundation
import ZkCredCore

/// JPKI over a PC/SC reader (contact or contactless) via CryptoTokenKit: the same APDUs as the iPhone's
/// `JPKIReader`, in one card session (the password verification only holds within it).
/// The certificate stays in memory; nothing is logged or written to disk.
enum SmartCardJPKI {
    enum ReaderError: LocalizedError {
        case noSmartCardService
        case noReader
        case noCard([String])
        case session
        case wrongPassword(remaining: Int)
        case passwordLocked
        case card(String, UInt8, UInt8)

        var errorDescription: String? {
            switch self {
            case .noSmartCardService: return "CryptoTokenKit smart card service is not available."
            case .noReader: return "No smart card reader found. Connect a USB reader."
            case .noCard(let readers): return "No card in the reader (\(readers.joined(separator: ", ")))."
            case .session: return "Could not open a session with the card."
            case .wrongPassword(let n): return "Wrong signing password. \(n) tries left before the certificate locks."
            case .passwordLocked: return "The signing password is locked. Reset it at your city office."
            case .card(let step, let sw1, let sw2): return String(format: "Card error at %@ (%02X%02X)", step, sw1, sw2)
            }
        }
    }

    /// Reader names, and which of them hold a card.
    static func readers() async throws -> [(name: String, hasCard: Bool)] {
        guard let manager = TKSmartCardSlotManager.default else { throw ReaderError.noSmartCardService }
        var out: [(String, Bool)] = []
        for name in manager.slotNames {
            let slot = await manager.getSlot(withName: name)
            out.append((name, slot?.state == .validCard))
        }
        return out
    }

    static func readAndSign(password: [UInt8], message: [UInt8], reader: String?) async throws
        -> (certificate: [UInt8], signature: [UInt8])
    {
        guard let manager = TKSmartCardSlotManager.default else { throw ReaderError.noSmartCardService }
        let names = manager.slotNames
        guard !names.isEmpty else { throw ReaderError.noReader }
        var card: TKSmartCard?
        for name in names where reader == nil || name == reader {
            if let slot = await manager.getSlot(withName: name), slot.state == .validCard,
               let c = slot.makeSmartCard()
            {
                card = c
                break
            }
        }
        guard let card else { throw ReaderError.noCard(names) }
        guard try await card.beginSession() else { throw ReaderError.session }
        defer { card.endSession() }
        return try await run(card, password: password, message: message)
    }

    private static func run(_ card: TKSmartCard, password: [UInt8], message: [UInt8]) async throws
        -> (certificate: [UInt8], signature: [UInt8])
    {
        _ = try await send(card, JPKIAPDU.selectAP(), step: "select JPKI")

        // Check remaining tries before spending one.
        _ = try await send(card, JPKIAPDU.selectEF(JPKIAPDU.EF.signPassword), step: "select password")
        let status = try await send(card, JPKIAPDU.verify(), step: "password status")
        if let left = JPKIAPDU.remainingTries(sw1: status.sw1, sw2: status.sw2), left == 0 {
            throw ReaderError.passwordLocked
        }
        let verified = try await send(card, JPKIAPDU.verify(password), step: "verify password")
        if let left = JPKIAPDU.remainingTries(sw1: verified.sw1, sw2: verified.sw2) {
            throw left == 0 ? ReaderError.passwordLocked : ReaderError.wrongPassword(remaining: left)
        }

        _ = try await send(card, JPKIAPDU.selectEF(JPKIAPDU.EF.signCertificate), step: "select certificate")
        let head = try await send(card, JPKIAPDU.readBinary(offset: 0, le: 4), step: "read certificate")
        let total = try DERLength.total(prefix: head.data)
        var cert: [UInt8] = []
        while cert.count < total {
            let want = min(256, total - cert.count)
            let chunk = try await send(
                card, JPKIAPDU.readBinary(offset: cert.count, le: UInt8(want & 0xFF)), step: "read certificate")
            if chunk.data.isEmpty { break }
            cert += chunk.data
        }

        let sig = try await send(card, JPKIAPDU.signSHA256DigestInfo(message), step: "sign")
        return (Array(cert.prefix(total)), sig.data)
    }

    /// Sends one APDU; follows 61xx (GET RESPONSE) and 6Cxx (wrong Le) as T=0 readers may return them.
    private static func send(_ card: TKSmartCard, _ apdu: [UInt8], step: String) async throws
        -> (data: [UInt8], sw1: UInt8, sw2: UInt8)
    {
        var (data, sw1, sw2) = try await transmit(card, apdu)
        if sw1 == 0x6C {
            (data, sw1, sw2) = try await transmit(card, Array(apdu.dropLast()) + [sw2])
        }
        while sw1 == 0x61 {
            let more = try await transmit(card, [0x00, 0xC0, 0x00, 0x00, sw2])
            data += more.data
            (sw1, sw2) = (more.sw1, more.sw2)
        }
        if !(sw1 == 0x90 && sw2 == 0x00) && JPKIAPDU.remainingTries(sw1: sw1, sw2: sw2) == nil {
            throw ReaderError.card(step, sw1, sw2)
        }
        return (data, sw1, sw2)
    }

    private static func transmit(_ card: TKSmartCard, _ apdu: [UInt8]) async throws
        -> (data: [UInt8], sw1: UInt8, sw2: UInt8)
    {
        let resp = Array(try await card.transmit(Data(apdu)))
        guard resp.count >= 2 else { throw ReaderError.card("transmit", 0, 0) }
        return (Array(resp.dropLast(2)), resp[resp.count - 2], resp[resp.count - 1])
    }
}
