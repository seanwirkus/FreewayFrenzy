import SwiftUI

@main
struct FreewayFrenzyApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            FullScreenHost {
                GameView()
            }
            #else
            GameView()
            #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 900)
        #endif
    }
}
