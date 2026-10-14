import SwiftUI
import Vatio

/// The drawer, as in ChatGPT: "New chat" at the top, this visitor's past
/// conversations from `vatio.conversations(visitorToken:)` newest first, and
/// Settings at the bottom.
struct ConversationsSidebar: View {
    let conversations: [VatioConversation]
    /// The conversation on screen, highlighted in the list.
    let currentID: Int?
    let isLoading: Bool
    var onNewChat: () -> Void
    var onSelect: (VatioConversation) -> Void
    var onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onNewChat) {
                Label("New chat", systemImage: "square.and.pencil")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }

            Divider()

            if conversations.isEmpty {
                Text(isLoading ? "Loading…" : "No conversations yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                Spacer()
            } else {
                List(conversations) { conversation in
                    row(for: conversation)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            Divider()

            Button(action: onSettings) {
                Label("Settings", systemImage: "gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .foregroundStyle(.primary)
        }
        .background {
            Color(.secondarySystemBackground).ignoresSafeArea()
        }
    }

    private func row(for conversation: VatioConversation) -> some View {
        Button {
            onSelect(conversation)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title(of: conversation))
                    .lineLimit(1)
                if let date = conversation.updatedAt ?? conversation.startedAt {
                    Text(date.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(conversation.id == currentID ? Color(.tertiarySystemFill) : Color.clear)
    }

    // The title is what the visitor opened with; the preview, the last thing said.
    private func title(of conversation: VatioConversation) -> String {
        if !conversation.title.isEmpty { return conversation.title }
        if !conversation.preview.isEmpty { return conversation.preview }
        return "New conversation"
    }
}
