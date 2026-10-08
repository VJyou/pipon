import Foundation
import SwiftUI
import ZkCredCore

/// Request → card (NFC, or a dummy card in development) → checks → proof → relay.
/// Only the proof, its public signals and the nonce leave the phone.
@MainActor
final class ProveFlow: ObservableObject {
    enum Stage: Equatable {
        case idle
        case loading
        case ready
        case reading
        case proving
        case sending
        case done(seconds: Double)
        case failed(String)
    }

    enum Card {
        case nfc(password: [UInt8])
        /// Dummy card bundled in development builds (Circuit/dev/<name>.der + .pem).
        case dev(String)
        /// Demo card for people without a My Number Card: a dummy card (dummy CA, dummy person, TEST key) issued once
        /// per install by the demo site that sent the request (`POST /api/demo-card`), then kept on this phone.
        case demo
    }

    enum FlowError: LocalizedError {
        case missing(String)
        case relay(Int)
        case underAge(threshold: Int)

        var errorDescription: String? {
            switch self {
            case .missing(let what): return "Missing \(what) in the app bundle (run fetch-artifacts.sh)."
            case .relay(let code): return "The demo site answered HTTP \(code)."
            case .underAge(let t): return "This card does not satisfy age \(t)+, so no proof exists."
            }
        }
    }

    /// The circuit's public age threshold; the demo gate and shop both require 20+.
    static let ageThreshold = 20

    @Published private(set) var stage: Stage = .idle
    @Published private(set) var request: ProofRequest?
    private var sessionURL: URL?

    /// Dummy cards bundled for development, e.g. ["osaka40", "tokyo17", "tokyo20"].
    let devCards: [String] = (Bundle.main.paths(forResourcesOfType: "der", inDirectory: nil))
        .map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
        .filter { $0.range(of: "^[a-z]+[0-9]+$", options: .regularExpression) != nil
            && Bundle.main.path(forResource: $0, ofType: "pem") != nil }
        .sorted()

    func open(deepLink: String) async {
        stage = .loading
        request = nil
        do {
            let url = try ProofRequest.sessionURL(fromDeepLink: deepLink)
            let (data, resp) = try await URLSession.shared.data(from: url)
            try Self.check(resp)
            struct Envelope: Decodable { let request: ProofRequest }
            request = try JSONDecoder().decode(Envelope.self, from: data).request
            sessionURL = url
            stage = .ready
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }

    func prove(with card: Card) async {
        guard let request, let sessionURL else { return }
        let started = Date()
        do {
            let nonce = UInt64.random(in: 1...UInt64(UInt32.max))
            let message = CircuitInput.challengeMessage(binding: try request.bindingBytes(), nonce: nonce)

            stage = .reading
            let (certificate, signature, demoCA) = try await read(card, message: message)

            // Cheap checks before seconds of proving: the card signed this challenge, a trusted CA signed the card.
            try TrustAnchors.checkChallenge(certificateDER: certificate, message: message, signature: signature)
            // The demo card's dummy CA is trusted for the demo card only; real cards need a J-LIS CA.
            let caModulus = try TrustAnchors.issuerModulus(
                of: certificate, among: try Self.trustedCAs() + (demoCA.map { [$0] } ?? []))
            let input = try CircuitInput(certificateDER: certificate)
            let today = Self.todayJST()
            guard input.facts.age(on: today) >= Self.ageThreshold else {
                throw FlowError.underAge(threshold: Self.ageThreshold)
            }
            let json = try input.json(
                caModulus: caModulus, challengeMessage: message, challengeSignature: signature,
                currentDate: today, ageThreshold: Self.ageThreshold, scope: request.scope)
            let inputs = String(decoding: try JSONSerialization.data(withJSONObject: json), as: UTF8.self)

            stage = .proving
            guard let zkey = Bundle.main.path(forResource: "jpki_age_region", ofType: "zkey") else {
                throw FlowError.missing("jpki_age_region.zkey")
            }
            let proof = try await Task.detached(priority: .userInitiated) {
                try generateCircomProof(zkeyPath: zkey, circuitInputs: inputs, proofLib: .rapidsnark)
            }.value

            stage = .sending
            let p = proof.proof
            let result = ProofResult(
                proof: .init(
                    a: [p.a.x, p.a.y, p.a.z],
                    b: [p.b.x, p.b.y, p.b.z],
                    c: [p.c.x, p.c.y, p.c.z]),
                publicSignals: proof.inputs, nonce: nonce)
            var post = URLRequest(url: sessionURL.appendingPathComponent("result"))
            post.httpMethod = "POST"
            post.setValue("application/json", forHTTPHeaderField: "content-type")
            post.httpBody = try JSONEncoder().encode(result)
            let (_, resp) = try await URLSession.shared.data(for: post)
            try Self.check(resp)
            stage = .done(seconds: Date().timeIntervalSince(started))
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }

    private func read(_ card: Card, message: [UInt8]) async throws -> ([UInt8], [UInt8], [UInt8]?) {
        switch card {
        case .nfc(let password):
            #if canImport(CoreNFC)
            let out = try await JPKIReader().readAndSign(password: password, message: message)
            return (out.certificateDER, out.challengeSignature, nil)
            #else
            throw FlowError.missing("NFC")
            #endif
        case .dev(let name):
            guard let der = Bundle.main.url(forResource: name, withExtension: "der"),
                  let pem = Bundle.main.url(forResource: name, withExtension: "pem")
            else { throw FlowError.missing("dev card \(name)") }
            let certificate = Array(try Data(contentsOf: der))
            let signature = try DevCard.sign(message, privateKeyPEM: try String(contentsOf: pem, encoding: .utf8))
            return (certificate, signature, nil)
        case .demo:
            guard let sessionURL else { throw FlowError.missing("request") }
            let card = try await DemoCard.load(site: sessionURL)
            return (card.certificate, try DevCard.sign(message, privateKeyPEM: card.privateKeyPEM), card.caCertificate)
        }
    }

    /// J-LIS signing CAs, plus the dummy CA when development cards are bundled.
    static func trustedCAs() throws -> [[UInt8]] {
        let names = ["signca01", "signca02", "signca03"]
        var cas = try names.map { name -> [UInt8] in
            guard let url = Bundle.main.url(forResource: name, withExtension: "cer") else {
                throw FlowError.missing("\(name).cer")
            }
            return Array(try Data(contentsOf: url))
        }
        if let dummy = Bundle.main.url(forResource: "dummy-ca", withExtension: "der") {
            cas.append(Array(try Data(contentsOf: dummy)))
        }
        return cas
    }

    /// YYYYMMDD in Japan time (zk_gate accepts today or the previous days in JST).
    static func todayJST() -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let c = cal.dateComponents([.year, .month, .day], from: Date())
        return c.year! * 10_000 + c.month! * 100 + c.day!
    }

    private static func check(_ resp: URLResponse) throws {
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw FlowError.relay(http.statusCode)
        }
    }
}
