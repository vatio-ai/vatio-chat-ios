import SwiftUI
import Vatio

/// What a new conversation opens on: the agent's face, its greeting and its
/// suggested questions, all from `vatio.config()`. A suggestion is sent as if
/// the visitor had typed it.
struct EmptyState: View {
    let config: VatioConfig?
    var onSuggestion: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 14) {
                AgentAvatar(name: config?.agentName, url: config?.avatarURL, size: 64)
                Text(greeting)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                if let about = config?.about, !about.isEmpty {
                    Text(about)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            Spacer()
            if let suggestions = config?.suggestions, !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                onSuggestion(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(3)
                                    .frame(width: 180, alignment: .topLeading)
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var greeting: String {
        if let greeting = config?.greeting, !greeting.isEmpty { return greeting }
        return "How can I help?"
    }
}
