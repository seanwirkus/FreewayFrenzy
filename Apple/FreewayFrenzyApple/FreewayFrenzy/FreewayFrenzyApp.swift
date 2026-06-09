import SwiftUI

@main
struct FreewayFrenzyApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 900)
        #endif
    }
}
