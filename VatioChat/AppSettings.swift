import Foundation

/// What the Settings screen can change, kept in UserDefaults. Until someone
/// saves, it is AppConfig's agent with no signed-in user.
struct AppSettings: Equatable {
    var workspace = AppConfig.workspace
    var token = AppConfig.token
    var baseURL = AppConfig.baseURL
    /// A JWT your backend signed for the signed-in user (see
    /// vatio.ai/docs/authentication/sessions). Empty means anonymous.
    var visitorToken = ""

    /// What `VatioChat` and `conversations(visitorToken:)` take: nil, not an
    /// empty string, for an anonymous visitor.
    var visitorTokenIfSet: String? { visitorToken.isEmpty ? nil : visitorToken }

    var url: URL? {
        guard let url = URL(string: baseURL), url.scheme == "https" || url.scheme == "http", url.host() != nil else {
            return nil
        }
        return url
    }

    /// The SDK checks the token kind too, but only once it makes a request;
    /// catching it here keeps a typo from replacing a working setup.
    var isValid: Bool {
        !workspace.isEmpty && token.hasPrefix("vatpub_") && url != nil
    }

    /// Trims what was pasted, so a stray space or newline doesn't break the token.
    var trimmed: AppSettings {
        AppSettings(
            workspace: workspace.trimmingCharacters(in: .whitespacesAndNewlines),
            token: token.trimmingCharacters(in: .whitespacesAndNewlines),
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            visitorToken: visitorToken.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: - Storage

    private enum Key {
        static let workspace = "settings.workspace"
        static let token = "settings.token"
        static let baseURL = "settings.baseURL"
        static let visitorToken = "settings.visitorToken"
    }

    static func load(from defaults: UserDefaults = .standard) -> AppSettings {
        var settings = AppSettings()
        settings.workspace = defaults.string(forKey: Key.workspace) ?? settings.workspace
        settings.token = defaults.string(forKey: Key.token) ?? settings.token
        settings.baseURL = defaults.string(forKey: Key.baseURL) ?? settings.baseURL
        settings.visitorToken = defaults.string(forKey: Key.visitorToken) ?? settings.visitorToken
        return settings
    }

    // A real app keeps a user's token in the Keychain, or better, asks its
    // backend for a fresh one. This one is pasted in by hand for testing.
    func save(to defaults: UserDefaults = .standard) {
        defaults.set(workspace, forKey: Key.workspace)
        defaults.set(token, forKey: Key.token)
        defaults.set(baseURL, forKey: Key.baseURL)
        defaults.set(visitorToken, forKey: Key.visitorToken)
    }
}
