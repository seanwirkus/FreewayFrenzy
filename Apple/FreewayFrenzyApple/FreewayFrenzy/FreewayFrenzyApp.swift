import SwiftUI

@main
struct FreewayFrenzyApp: App {
    var body: some Scene {
        WindowGroup {
            // GameView paints edge-to-edge via `.ignoresSafeArea(.all)`. The old
            // iOS `FullScreenHost` (a UIHostingController nested in the WindowGroup)
            // was left unconstrained and collapsed the whole UI to a 320×480 hosting
            // default, letterboxing gameplay. Hosting GameView directly fills the
            // window on every device.
            GameView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 900)
        #endif
    }
}
