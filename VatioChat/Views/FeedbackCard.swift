import SwiftUI
import Vatio

/// Vatio's feedback moment, drawn after the agent's last message while
/// `chat.feedback` is open. The SDK only says when to ask and takes the
/// answer; how the question looks is up to the app.
@MainActor
struct FeedbackCard: View {
    let feedback: VatioFeedback
    var onRate: (VatioFeedback.Rating, String?) async -> Void
    var onDismiss: () async -> Void

    @State private var picked: VatioFeedback.Rating?
    @State private var comment = ""
    @State private var isSending = false

    private static let maxCommentLength = 2_000

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(feedback.question ?? "How did \(feedback.agentName) do?")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                ForEach(VatioFeedback.Rating.allCases, id: \.self) { rating in
                    if picked == rating {
                        ratingButton(rating).buttonStyle(.borderedProminent)
                    } else {
                        ratingButton(rating).buttonStyle(.bordered)
                    }
                }
            }

            // "Good" goes straight out; "So-so" and "Bad" ask what went wrong.
            if let picked, picked != .good {
                TextField("What could have been better? (optional)", text: $comment, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: comment) { _, newValue in
                        if newValue.count > Self.maxCommentLength {
                            comment = String(newValue.prefix(Self.maxCommentLength))
                        }
                    }
                Button("Send feedback") {
                    let text = comment.trimmingCharacters(in: .whitespacesAndNewlines)
                    submit { await onRate(picked, text.isEmpty ? nil : text) }
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Not now") {
                submit { await onDismiss() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .disabled(isSending)
    }

    private func ratingButton(_ rating: VatioFeedback.Rating) -> some View {
        Button {
            choose(rating)
        } label: {
            Text(Self.title(of: rating))
                .font(.subheadline)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
    }

    private func choose(_ rating: VatioFeedback.Rating) {
        picked = rating
        if rating == .good {
            submit { await onRate(.good, nil) }
        }
    }

    /// The card goes away on its own once the answer lands, because
    /// `feedback.isOpen` turns false; until then the buttons stay disabled.
    private func submit(_ answer: @escaping () async -> Void) {
        isSending = true
        Task {
            await answer()
            isSending = false
        }
    }

    private static func title(of rating: VatioFeedback.Rating) -> String {
        switch rating {
        case .good: return "Good"
        case .neutral: return "So-so"
        case .bad: return "Bad"
        }
    }
}
