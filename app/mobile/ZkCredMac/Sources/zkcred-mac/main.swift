import Foundation
import ZkCredCore

// zkcred-mac — the iPhone app's request flow on a Mac with a USB smart card reader.
//
//   zkcred-mac readers
//   zkcred-mac prove '<pipon://prove?s=...>' [--reader <name>] [--dev <card>]
//
// Request → card (PC/SC reader, or a dummy card with --dev) → checks → proof (ZkCredProver `prove`) → relay.
// Only the proof, its public signals and the nonce leave this process; circuit inputs go to the prover over a pipe.

let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
/// Same files the iOS app bundles (`ZkCredProver/ios/fetch-artifacts.sh [--dev]`).
let circuitDir = repoRoot.appendingPathComponent("app/mobile/ZkCredProver/ios/MoproApp/Circuit")
let proverBinary = repoRoot.appendingPathComponent("app/mobile/ZkCredProver/target/release/prove")
let ageThreshold = 20

enum CLIError: LocalizedError {
    case usage
    case missing(String)
    case relay(Int)
    case underAge
    case badPassword
    case prover(String)

    var errorDescription: String? {
        switch self {
        case .usage: return "usage: zkcred-mac readers | zkcred-mac prove '<pipon://prove?s=...>' [--reader <name>] [--dev <card>]"
        case .missing(let what): return "Missing \(what)."
        case .relay(let code): return "The demo site answered HTTP \(code)."
        case .underAge: return "This card does not satisfy age \(ageThreshold)+, so no proof exists."
        case .badPassword: return "The signing password is 6–16 letters or digits."
        case .prover(let msg): return "Prover failed: \(msg)"
        }
    }
}

func log(_ s: String) { FileHandle.standardError.write(Data((s + "\n").utf8)) }

func file(_ name: String) throws -> [UInt8] {
    let url = circuitDir.appendingPathComponent(name)
    guard let d = try? Data(contentsOf: url) else {
        throw CLIError.missing("\(url.path) (run ZkCredProver/ios/fetch-artifacts.sh)")
    }
    return Array(d)
}

/// J-LIS signing CAs, plus the dummy CA when development cards are present.
func trustedCAs() throws -> [[UInt8]] {
    var cas = try ["signca01.cer", "signca02.cer", "signca03.cer"].map(file)
    if let dummy = try? file("dev/dummy-ca.der") { cas.append(dummy) }
    return cas
}

/// YYYYMMDD in Japan time (zk_gate accepts today or the previous days in JST).
func todayJST() -> Int {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    let c = cal.dateComponents([.year, .month, .day], from: Date())
    return c.year! * 10_000 + c.month! * 100 + c.day!
}

func check(_ resp: URLResponse) throws {
    if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        throw CLIError.relay(http.statusCode)
    }
}

func readPassword() throws -> [UInt8] {
    var buf = [CChar](repeating: 0, count: 64)
    defer { for i in buf.indices { buf[i] = 0 } }
    guard readpassphrase("Signing password (6-16 letters/digits): ", &buf, buf.count, RPP_ECHO_OFF) != nil,
          let pw = JPKIAPDU.normalizedPassword(String(cString: buf))
    else { throw CLIError.badPassword }
    return pw
}

/// Runs the Rust prover with the inputs on stdin; returns its JSON output.
func runProver(inputs: Data) throws -> Data {
    guard FileManager.default.isExecutableFile(atPath: proverBinary.path) else {
        throw CLIError.missing("\(proverBinary.path) (cd app/mobile/ZkCredProver && cargo build --release --bin prove)")
    }
    let p = Process()
    p.executableURL = proverBinary
    p.arguments = [circuitDir.appendingPathComponent("jpki_age_region.zkey").path]
    let stdin = Pipe(), stdout = Pipe(), stderr = Pipe()
    p.standardInput = stdin
    p.standardOutput = stdout
    p.standardError = stderr
    try p.run()
    stdin.fileHandleForWriting.write(inputs)
    try stdin.fileHandleForWriting.close()
    let out = stdout.fileHandleForReading.readDataToEndOfFile()
    let err = stderr.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    guard p.terminationStatus == 0 else { throw CLIError.prover(String(decoding: err, as: UTF8.self)) }
    return out
}

struct ProverOutput: Decodable {
    struct Points: Decodable {
        let a: [String]
        let b: [[String]]
        let c: [String]
    }
    let proof: Points
    let publicSignals: [String]
}

func prove(deepLink: String, reader: String?, devCard: String?) async throws {
    let sessionURL = try ProofRequest.sessionURL(fromDeepLink: deepLink)
    let (data, resp) = try await URLSession.shared.data(from: sessionURL)
    try check(resp)
    struct Envelope: Decodable { let request: ProofRequest }
    let request = try JSONDecoder().decode(Envelope.self, from: data).request
    log("Request from \(request.service): \(request.statement.joined(separator: ", "))")

    let nonce = UInt64.random(in: 1...UInt64(UInt32.max))
    let message = CircuitInput.challengeMessage(binding: try request.bindingBytes(), nonce: nonce)

    let certificate: [UInt8], signature: [UInt8]
    if let devCard {
        certificate = try file("dev/\(devCard).der")
        let pem = String(decoding: try file("dev/\(devCard).pem"), as: UTF8.self)
        signature = try DevCard.sign(message, privateKeyPEM: pem)
    } else {
        let password = try readPassword()
        log("Reading the card…")
        (certificate, signature) = try await SmartCardJPKI.readAndSign(password: password, message: message, reader: reader)
    }

    // Cheap checks before seconds of proving: the card signed this challenge, a trusted CA signed the card.
    try TrustAnchors.checkChallenge(certificateDER: certificate, message: message, signature: signature)
    let caModulus = try TrustAnchors.issuerModulus(of: certificate, among: try trustedCAs())
    let input = try CircuitInput(certificateDER: certificate)
    let today = todayJST()
    guard input.facts.age(on: today) >= ageThreshold else { throw CLIError.underAge }
    let json = try input.json(
        caModulus: caModulus, challengeMessage: message, challengeSignature: signature,
        currentDate: today, ageThreshold: ageThreshold, scope: request.scope)

    log("Proving…")
    let started = Date()
    let out = try JSONDecoder().decode(
        ProverOutput.self, from: try runProver(inputs: try JSONSerialization.data(withJSONObject: json)))
    log(String(format: "Proof in %.1f s. Sending…", Date().timeIntervalSince(started)))

    let result = ProofResult(
        proof: .init(a: out.proof.a, b: out.proof.b, c: out.proof.c), publicSignals: out.publicSignals, nonce: nonce)
    var post = URLRequest(url: sessionURL.appendingPathComponent("result"))
    post.httpMethod = "POST"
    post.setValue("application/json", forHTTPHeaderField: "content-type")
    post.httpBody = try JSONEncoder().encode(result)
    let (_, postResp) = try await URLSession.shared.data(for: post)
    try check(postResp)
    log("Done. Check the demo page.")
}

func option(_ name: String, in args: [String]) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    return args[i + 1]
}

let args = Array(CommandLine.arguments.dropFirst())
do {
    switch args.first {
    case "readers":
        let list = try await SmartCardJPKI.readers()
        if list.isEmpty { log("No readers.") }
        for r in list { print("\(r.name)\t\(r.hasCard ? "card present" : "empty")") }
    case "prove" where args.count >= 2:
        try await prove(deepLink: args[1], reader: option("--reader", in: args), devCard: option("--dev", in: args))
    default:
        throw CLIError.usage
    }
} catch {
    log("Error: \(error.localizedDescription)")
    exit(1)
}
