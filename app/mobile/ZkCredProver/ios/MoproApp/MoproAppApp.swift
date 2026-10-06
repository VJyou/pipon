//
//  MoproAppApp.swift
//  MoproApp
//

import SwiftUI

@main
struct MoproAppApp: App {
    @StateObject private var flow = ProveFlow()

    var body: some Scene {
        WindowGroup {
            ContentView(flow: flow)
                // zkcred://prove?s=<relay session URL> from the demo site's QR code
                .onOpenURL { url in Task { await flow.open(deepLink: url.absoluteString) } }
        }
    }
}
