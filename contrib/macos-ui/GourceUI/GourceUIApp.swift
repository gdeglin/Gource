import SwiftUI

@main
struct GourceUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 820, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 780)
    }
}
