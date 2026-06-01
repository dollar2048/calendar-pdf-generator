import SwiftUI

@main
struct CalendarApp: App {
    var body: some Scene {
        WindowGroup {
            GalleryView()
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 760)
        #endif
    }
}
