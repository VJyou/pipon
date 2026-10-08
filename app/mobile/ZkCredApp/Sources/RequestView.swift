import SwiftUI
import ZkCredCore

/// The main screen: what a service asks for, the card, and the result. Personal data never appears here.
struct RequestView: View {
    @ObservedObject var flow: ProveFlow
    @State private var password = ""
    @State private var source: CardSource = .myNumber
    @State private var devCard = ""
    @State private var pastedLink = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let request = flow.request {
                Text(request.service).font(.headline)
                Text("asks you to prove:").font(.subheadline).foregroundStyle(.secondary)
                ForEach(request.statement, id: \.self) { Label($0, systemImage: "checkmark.seal") }
                Text("Your name, date of birth, address and My Number stay on this phone.")
                    .font(.footnote).foregroundStyle(.secondary)
                cardPicker
                Button(busy ? "Working…" : "Prove") { start() }
                    .buttonStyle(.borderedProminent)
                    .disabled(busy || !canStart)
            } else {
                Text("Scan the QR code on the demo site with the iPhone camera.").foregroundStyle(.secondary)
                HStack {
                    TextField("or paste a pipon:// link", text: $pastedLink)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Open") { Task { await flow.open(deepLink: pastedLink) } }
                        .disabled(!pastedLink.hasPrefix("pipon://"))
                }
            }
            status
        }
        .onAppear {
            devCard = flow.devCards.first ?? ""
            // `-openLink <pipon://…>` launch argument: open a request without the system's "Open in…" prompt (simctl).
            if let link = UserDefaults.standard.string(forKey: "openLink"), flow.request == nil {
                Task { await flow.open(deepLink: link) }
            }
        }
        .onChange(of: flow.stage) { _, stage in
            // `-autoDevCard <name>` launch argument: prove with that dummy card as soon as a request arrives.
            if stage == .ready, let name = UserDefaults.standard.string(forKey: "autoDevCard"),
               flow.devCards.contains(name) {
                Task { await flow.prove(with: .dev(name)) }
            }
            // `-autoDemoCard YES` launch argument: the same with the demo card (e2e against the public demo).
            if stage == .ready, UserDefaults.standard.bool(forKey: "autoDemoCard") {
                Task { await flow.prove(with: .demo) }
            }
        }
    }

    enum CardSource: Hashable { case myNumber, demo, dev }

    @ViewBuilder private var cardPicker: some View {
        Picker("Card", selection: $source) {
            Text("My Number Card").tag(CardSource.myNumber)
            Text("Demo card").tag(CardSource.demo)
            if !flow.devCards.isEmpty { Text("Dev").tag(CardSource.dev) }
        }
        .pickerStyle(.segmented)
        switch source {
        case .demo:
            Text("No My Number Card? The demo site issues a dummy card (test authority, dummy person) to this phone. "
                + "Proving is the same as with a real card; only the demo services accept it.")
                .font(.footnote).foregroundStyle(.secondary)
        case .dev:
            Picker("Dummy card", selection: $devCard) {
                ForEach(flow.devCards, id: \.self) { Text($0) }
            }
        case .myNumber:
            SecureField("Signing password (6–16 characters)", text: $password)
                .keyboardType(.asciiCapable)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder private var status: some View {
        switch flow.stage {
        case .idle, .ready: EmptyView()
        case .loading: Label("Loading the request…", systemImage: "arrow.down.circle")
        case .reading: Label("Reading the card…", systemImage: "wave.3.right")
        case .proving: Label("Proving on this phone…", systemImage: "cpu")
        case .sending: Label("Sending the proof…", systemImage: "paperplane")
        case .done(let s):
            Label(String(format: "Proof sent (%.1f s). Return to the demo site.", s), systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        case .failed(let message): Label(message, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
        }
    }

    private var busy: Bool {
        switch flow.stage {
        case .loading, .reading, .proving, .sending: return true
        default: return false
        }
    }

    private var canStart: Bool {
        switch source {
        case .myNumber: return JPKIAPDU.normalizedPassword(password) != nil
        case .demo: return true
        case .dev: return !devCard.isEmpty
        }
    }

    private func start() {
        let card: ProveFlow.Card
        switch source {
        case .myNumber:
            guard let secret = JPKIAPDU.normalizedPassword(password) else { return }
            card = .nfc(password: secret)
        case .demo: card = .demo
        case .dev: card = .dev(devCard)
        }
        password = ""
        Task { await flow.prove(with: card) }
    }
}
