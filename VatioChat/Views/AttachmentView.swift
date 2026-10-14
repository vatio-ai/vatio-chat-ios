import SwiftUI
import Vatio

/// A file on a message: a thumbnail for an image, a chip for anything else.
/// The `url` is signed and loads without the chat credential, so it opens in
/// the browser as is. While the message is pending there is no URL yet.
struct AttachmentView: View {
    let attachment: VatioAttachment

    var body: some View {
        switch attachment.kind {
        case .image:
            linked(thumbnail)
        case .audio:
            linked(chip("Voice note", systemImage: "waveform"))
        case .video, .file:
            linked(chip(attachment.filename, systemImage: "doc"))
        }
    }

    private var thumbnail: some View {
        AsyncImage(url: attachment.url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Color(.secondarySystemBackground)
                    .overlay {
                        Image(systemName: "photo").foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 180, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func chip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground), in: Capsule())
    }

    @ViewBuilder
    private func linked<Content: View>(_ content: Content) -> some View {
        if let url = attachment.url {
            Link(destination: url) { content }
        } else {
            content
        }
    }
}
