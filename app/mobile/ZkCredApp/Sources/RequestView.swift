import SwiftUI
import ZkCredCore

/// The main screen: what a service asks for, the card, and the result. Personal data never appears here.
struct RequestView: View {
    @ObservedObject var flow: ProveFlow
    @State private var password = ""
    @State private var useDevCard = false
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
        }
    }

    @ViewBuilder private var cardPicker: some View {
        if !flow.devCards.isEmpty {
            Toggle("Use a dummy card (development)", isOn: $useDevCard)
        }
        if useDevCard {
            Picker("Dummy card", selection: $devCard) {
                ForEach(flow.devCards, id: \.self) { Text($0) }
            }
        } else {
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
        useDevCard ? !devCard.isEmpty : JPKIAPDU.normalizedPassword(password) != nil
    }

    private func start() {
        let card: ProveFlow.Card
        if useDevCard {
            card = .dev(devCard)
        } else {
            guard let secret = JPKIAPDU.normalizedPassword(password) else { return }
            card = .nfc(password: secret)
        }
        password = ""
        Task { await flow.prove(with: card) }
    }
}
