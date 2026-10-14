import SwiftUI
import Vatio

/// The main screen for one `VatioChat`: the top bar, the conversation and the
/// composer. `RootView` rebuilds it when the store swaps the chat.
@MainActor
struct ChatView: View {
    @ObservedObject var store: ChatStore
    @ObservedObject var chat: VatioChat
    var onOpenDrawer: () -> Void

    var body: some View {
        MessageList(
            chat: chat,
            config: store.config,
            isLoading: store.isLoadingConversation,
            onSuggestion: { suggestion in
                Task { _ = await store.send(suggestion, attachments: []) }
            },
            onRate: { rating, comment in
                await store.rate(rating, comment: comment)
            },
            onDismissFeedback: {
                await store.dismissFeedback()
            }
        )
        .safeAreaInset(edge: .bottom) {
            Composer(
                onSend: { text, attachments in
                    await store.send(text, attachments: attachments)
                },
                onError: { error in
                    store.show(error)
                }
            )
        }
        .navigationTitle(store.agentName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onOpenDrawer) {
                    Image(systemName: "line.3.horizontal")
                }
                .accessibilityLabel("Conversations")
            }
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(store.agentName).font(.headline)
                    if let status = statusText {
                        Text(status).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.startNewChat()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("New chat")
                .disabled(chat.messages.isEmpty)
            }
        }
        // Runs for every new chat, since a new chat is a new view: reopen the
        // visitor's stored conversation, if any, and load the agent's branding.
        .task { await store.resume() }
        .task { await store.loadConfig() }
        // Failures outside `send` (a reply that couldn't be fetched, an
        // expired credential) land here instead of being thrown.
        .onChange(of: chat.lastError) { _, error in
            if let error { store.show(error) }
        }
    }

    private var statusText: String? {
        switch chat.status {
        case .connecting: return "Connecting…"
        case .reconnecting: return "Reconnecting…"
        case .idle, .connected, .closed: return nil
        }
    }
}
