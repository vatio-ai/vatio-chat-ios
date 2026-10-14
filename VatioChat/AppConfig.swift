import Foundation

/// The agent the app talks to out of the box: Vatio's own, the one that
/// answers on vatio.ai.
///
/// To point the app at your agent, put your workspace and a publishable token
/// here. The token only works from origins it allows, and an iOS app's origin
/// is `ios-app://` plus its bundle id, so create it with this app's:
///
///     vatio tokens create --env preview --origin ios-app://ai.vatio.chat
///
/// (`--env live` for production; change the origin if you change the bundle
/// id.) A publishable `vatpub_` token is meant to ship inside an app. A `vat_`
/// token is a developer secret: never put one in an app.
enum AppConfig {
    static let workspace = "vatio"
    static let token = "vatpub_472bb67e31a2a3c47c9d11c057cbfb76d4854d19ea582e59"
    static let baseURL = "https://vatio.ai"

    static let repositoryURL = URL(string: "https://github.com/vatio-ai/vatio-chat-ios")!
    static let docsURL = URL(string: "https://vatio.ai/docs/sdk/ios")!
}
