import SwiftUI

/// The request flow, plus developer tools: card check (real card, layout only) and a proof of the dummy fixture
/// (circuits/fixtures/dummy) reporting time and memory. Run ./fetch-artifacts.sh first (zkey, CA certs, inputs).
struct ContentView: View {
  @ObservedObject var flow: ProveFlow
  @State private var log: [String] = []
  @State private var running = false

  private let zkeyPath = Bundle.main.path(forResource: "jpki_age_region", ofType: "zkey")
  private let inputPath = Bundle.main.path(forResource: "dummy_input", ofType: "json")

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("p!pon").font(.title2).bold()
        RequestView(flow: flow)
        Divider()
        DisclosureGroup("Developer") {
          VStack(alignment: .leading, spacing: 12) {
            Button(running ? "Proving…" : "Prove dummy fixture") { run() }
              .buttonStyle(.bordered)
              .disabled(running || zkeyPath == nil || inputPath == nil)
            if zkeyPath == nil || inputPath == nil {
              Text("Missing Circuit/ resources: run fetch-artifacts.sh").foregroundStyle(.red)
            }
            Text(log.joined(separator: "\n"))
              .font(.system(.footnote, design: .monospaced))
              .frame(maxWidth: .infinity, alignment: .leading)
              .textSelection(.enabled)
            Divider()
            CardCheckView()
          }
          .padding(.top, 8)
        }
      }
    }
    .padding()
    .onAppear {
      // `-autoprove` launch argument: run once on launch (simctl/CI), results also go to stdout.
      if ProcessInfo.processInfo.arguments.contains("-autoprove") { run() }
    }
  }

  private func run() {
    guard let zkeyPath, let inputPath else { return }
    running = true
    log = ["memory before: \(Self.footprintMB()) MB"]
    Task.detached(priority: .userInitiated) {
      var lines: [String] = []
      do {
        let input = try String(contentsOfFile: inputPath, encoding: .utf8)
        let t0 = Date()
        let result = try generateCircomProof(
          zkeyPath: zkeyPath, circuitInputs: input, proofLib: ProofLib.rapidsnark)
        let proveSec = Date().timeIntervalSince(t0)
        lines.append(String(format: "prove (rapidsnark): %.2f s", proveSec))
        lines.append("memory after prove: \(Self.footprintMB()) MB")
        let t1 = Date()
        let ok = try verifyCircomProof(
          zkeyPath: zkeyPath, proofResult: result, proofLib: ProofLib.rapidsnark)
        lines.append(String(format: "verify: %@ (%.2f s)", ok ? "OK" : "FAILED", Date().timeIntervalSince(t1)))
        lines.append("public inputs (\(result.inputs.count)):")
        lines += result.inputs.map { "  \($0)" }
      } catch {
        lines.append("error: \(error)")
      }
      for line in lines { print("[prover] \(line)") }
      await MainActor.run {
        log += lines
        running = false
      }
    }
  }

  /// Physical footprint of this process (what iOS uses for jetsam limits).
  nonisolated static func footprintMB() -> Int {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
    let kr = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
      }
    }
    return kr == KERN_SUCCESS ? Int(info.phys_footprint / 1_048_576) : -1
  }
}

#Preview {
  ContentView(flow: ProveFlow())
}
