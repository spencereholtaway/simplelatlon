import SwiftUI

@main
struct XcodeLatLonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 760)
        #endif
    }
}
