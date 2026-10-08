import Foundation

/// The demo card (see `ProveFlow.Card.demo`): fetched once per demo site and kept in UserDefaults. Everything in it is
/// synthetic test data (dummy CA, dummy person, a TEST key), so it is not treated as a secret.
struct DemoCard: Codable {
    let label: String
    let certificate: [UInt8]
    let caCertificate: [UInt8]
    let privateKeyPEM: String

    private struct Response: Decodable {
        let label: String
        let certificate: String
        let caCertificate: String
        let privateKeyPEM: String
    }

    enum DemoCardError: LocalizedError {
        case site(Int)
        var errorDescription: String? {
            switch self {
            case .site(let code): return "The demo site could not issue a demo card (HTTP \(code))."
            }
        }
    }

    /// The demo site's origin, from the session URL in the QR code (e.g. https://host/api/session/<id>).
    static func origin(of url: URL) -> URL? {
        var c = URLComponents()
        c.scheme = url.scheme
        c.host = url.host
        c.port = url.port
        return c.url
    }

    static func load(site sessionURL: URL) async throws -> DemoCard {
        guard let origin = origin(of: sessionURL) else { throw URLError(.badURL) }
        let key = "demoCard:\(origin.absoluteString)"
        if let data = UserDefaults.standard.data(forKey: key), let card = try? JSONDecoder().decode(DemoCard.self, from: data) {
            return card
        }
        // One stable id per install, so a cleared cache fetches the same demo card (and nullifier) again.
        let idKey = "demoCardId"
        let cardId = UserDefaults.standard.string(forKey: idKey) ?? {
            let id = (0..<16).map { _ in String(format: "%02x", UInt8.random(in: 0...255)) }.joined()
            UserDefaults.standard.set(id, forKey: idKey)
            return id
        }()
        var req = URLRequest(url: origin.appendingPathComponent("api/demo-card"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONEncoder().encode(["cardId": cardId])
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw DemoCardError.site(http.statusCode)
        }
        let r = try JSONDecoder().decode(Response.self, from: data)
        guard let cert = Data(base64Encoded: r.certificate), let ca = Data(base64Encoded: r.caCertificate) else {
            throw URLError(.cannotParseResponse)
        }
        let card = DemoCard(label: r.label, certificate: Array(cert), caCertificate: Array(ca), privateKeyPEM: r.privateKeyPEM)
        UserDefaults.standard.set(try JSONEncoder().encode(card), forKey: key)
        return card
    }
}
