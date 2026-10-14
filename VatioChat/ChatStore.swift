import SwiftUI
import Vatio

/// Owns everything the screens show: the Vatio client, the current
/// conversation, the agent's branding, the conversation list and the settings.
///
/// A `VatioChat` takes its visitor token when it is created, so saving new
/// settings closes the chat and makes a new one. The views that draw a chat
/// hold it as `@ObservedObject` and are keyed by its identity, so they follow
/// the swap; the new one is resumed when its view appears.
@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var chat: VatioChat
    /// The agent's name, avatar, accent, greeting and suggestions; nil until
    /// it loads.
    @Published private(set) var config: VatioConfig?
    /// This visitor's conversations, newest first.
    @Published private(set) var conversations: [VatioConversation] = []
    @Published private(set) var isLoadingConversations = false
    /// A stored or picked conversation is loading, so the screen shows a
    /// spinner rather than the welcome screen it would otherwise flash.
    @Published private(set) var isLoadingConversation = false
    /// A short message for the banner; it clears itself.
    @Published var notice: String?

    private(set) var vatio: Vatio
    private var noticeTask: Task<Void, Never>?

    init() {
        let settings = AppSettings.load()
        let vatio = Self.client(for: settings)
        self.settings = settings
        self.vatio = vatio
        self.chat = VatioChat(vatio, visitorToken: settings.visitorTokenIfSet)
        isLoadingConversation = chat.canResume
    }

    var agentName: String { config?.agentName ?? "Vatio Chat" }

    /// The agent's accent when it has one, else the app's.
    var accent: Color { config?.accentColor.flatMap { Color(hex: $0) } ?? .accentColor }

    /// The origin the SDK sends, which the token must allow.
    var origin: String { "ios-app://\(vatio.appID.lowercased())" }

    // MARK: - Settings

    func apply(_ newSettings: AppSettings) {
        newSettings.save()
        settings = newSettings
        chat.close()
        vatio = Self.client(for: newSettings)
        chat = VatioChat(vatio, visitorToken: newSettings.visitorTokenIfSet)
        config = nil
        conversations = []
        isLoadingConversation = chat.canResume
    }

    private static func client(for settings: AppSettings) -> Vatio {
        Vatio(
            workspace: settings.workspace,
            token: settings.token,
            baseURL: settings.url ?? URL(string: AppConfig.baseURL)!
        )
    }

    // MARK: - Loading

    func loadConfig() async {
        let requested = settings
        do {
            let config = try await vatio.config()
            // Settings saved while this was in flight belong to another agent.
            guard requested == settings else { return }
            self.config = config
        } catch {
            guard requested == settings else { return }
            show(error)
        }
    }

    func loadConversations() async {
        let requested = settings
        isLoadingConversations = true
        defer { isLoadingConversations = false }
        do {
            let conversations = try await vatio.conversations(visitorToken: requested.visitorTokenIfSet)
            guard requested == settings else { return }
            self.conversations = conversations
        } catch {
            guard requested == settings else { return }
            show(error)
        }
    }

    // MARK: - Conversation

    /// Reopens the visitor's stored conversation, if there is one. The chat
    /// screen calls it whenever it shows a new chat.
    func resume() async {
        let resuming = chat
        await resuming.resume()
        // A chat replaced meanwhile has its own load under way.
        if resuming === chat { isLoadingConversation = false }
    }

    /// Sends a message, and returns false when it did not go out so the
    /// composer can put the draft back. The SDK has already taken the failed
    /// message out of `messages` by then.
    func send(_ text: String, attachments: [VatioUpload]) async -> Bool {
        let startsConversation = chat.conversationID == nil
        do {
            try await chat.send(text, attachments: attachments)
        } catch {
            show(error)
            return false
        }
        // The first message creates the conversation: list it in the drawer.
        if startsConversation { await loadConversations() }
        return true
    }

    func startNewChat() {
        chat.startOver()
    }

    func open(_ conversation: VatioConversation) async {
        let opening = chat
        isLoadingConversation = true
        do {
            try await opening.open(conversation)
        } catch {
            show(error)
        }
        if opening === chat { isLoadingConversation = false }
    }

    func rate(_ rating: VatioFeedback.Rating, comment: String?) async {
        do {
            try await chat.rate(rating, comment: comment)
        } catch {
            show(error)
        }
    }

    func dismissFeedback() async {
        do {
            try await chat.dismissFeedback()
        } catch {
            show(error)
        }
    }

    // MARK: - Errors

    /// Shows an error from `send`, from a load, or from `chat.lastError`.
    func show(_ error: Error) {
        guard let error = error as? VatioError else {
            show(message: error.localizedDescription)
            return
        }
        switch error.code {
        case "origin_not_allowed":
            show(message: "This token doesn't allow this app. Add \(origin) to the token's allowed origins.")
        case "subscription_rejected":
            show(message: "This conversation has expired. Your next message starts a new one.")
        case "no_conversation":
            // resume() found a stored conversation that belongs to another
            // signed-in user: there is simply nothing to reopen.
            return
        default:
            show(message: error.message)
        }
    }

    func show(message: String) {
        notice = message
        noticeTask?.cancel()
        noticeTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled { notice = nil }
        }
    }
}
