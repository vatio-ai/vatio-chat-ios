import SwiftUI
import Vatio

/// The conversation: the welcome screen until there is a message, then the
/// messages, the typing dots and the feedback card, kept scrolled to the end.
@MainActor
struct MessageList: View {
    @ObservedObject var chat: VatioChat
    let config: VatioConfig?
    /// A conversation is loading: show a spinner, not the welcome screen.
    let isLoading: Bool
    var onSuggestion: (String) -> Void
    var onRate: (VatioFeedback.Rating, String?) async -> Void
    var onDismissFeedback: () async -> Void

    private static let bottomID = "bottom"

    var body: some View {
        if chat.messages.isEmpty {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyState(config: config, onSuggestion: onSuggestion)
            }
        } else {
            messages
        }
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(chat.messages) { message in
                        MessageRow(message: message)
                    }
                    if let feedback = chat.feedback, feedback.isOpen {
                        FeedbackCard(feedback: feedback, onRate: onRate, onDismiss: onDismissFeedback)
                    }
                    if chat.isTyping {
                        TypingIndicator()
                    }
                    Color.clear.frame(height: 1).id(Self.bottomID)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { proxy.scrollTo(Self.bottomID, anchor: .bottom) }
            // A new message, a transcript filling in, the dots, or the card.
            .onChange(of: chat.messages) { scrollToEnd(proxy) }
            .onChange(of: chat.isTyping) { scrollToEnd(proxy) }
            .onChange(of: chat.feedback) { scrollToEnd(proxy) }
        }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(Self.bottomID, anchor: .bottom)
        }
    }
}
