import SwiftUI

/// Vatio Chat: a ChatGPT-style app for one Vatio agent, built on the Vatio iOS
/// SDK (https://github.com/vatio-ai/ios). The store is created once, here, and
/// lives as long as the app.
@main
struct VatioChatApp: App {
    @StateObject private var store = ChatStore()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}
