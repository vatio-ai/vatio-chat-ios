import SwiftUI
import Vatio

/// One message. The visitor's are right-aligned in a bubble, as typed; the
/// agent's run the full width with no bubble, rendered as Markdown.
struct MessageRow: View {
    let message: VatioMessage

    var body: some View {
        if message.isFromVisitor {
            visitorMessage
        } else {
            agentMessage
        }
    }

    private var visitorMessage: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ForEach(message.attachments) { attachment in
                AttachmentView(attachment: attachment)
            }
            if showsContent {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, 48)
        // Sent, but not confirmed by the server yet.
        .opacity(message.isPending ? 0.5 : 1)
    }

    private var agentMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(message.attachments) { attachment in
                AttachmentView(attachment: attachment)
            }
            if showsContent {
                MarkdownText(message.content)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // A message that was only a file carries a stand-in ("Image", "Audio")
    // as its content: the attachment says it better. A voice note's content
    // turns into its transcript a few seconds after sending, and then shows.
    private var showsContent: Bool {
        !message.isMediaLabel && !message.content.isEmpty
    }
}
