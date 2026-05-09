import SwiftUI

@main
struct NovaApp: App {
    init() {
        // 示範用：自動載入 sample songs
        PlayerManager.shared.setQueue(Song.samples, startAt: 0, playImmediately: false)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
