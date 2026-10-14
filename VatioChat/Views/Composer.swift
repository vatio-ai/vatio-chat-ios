import PhotosUI
import SwiftUI
import Vatio

/// The input at the bottom: a text field, a "+" for photos, and one button
/// that sends when there is something to send and records a voice note when
/// there isn't (tap again to send it, or ✕ to discard it). Limits are the
/// SDK's: 4 files of up to 8 MB, 4,000 characters.
@MainActor
struct Composer: View {
    /// Returns false when the message didn't go out, to put the draft back.
    var onSend: (String, [VatioUpload]) async -> Bool
    var onError: (Error) -> Void

    @State private var text = ""
    @State private var attachments: [DraftAttachment] = []
    @State private var pickedPhotos: [PhotosPickerItem] = []
    @StateObject private var recorder = VoiceRecorder()

    private static let maxLength = 4_000

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !attachments.isEmpty {
                attachmentStrip
            }
            HStack(alignment: .bottom, spacing: 8) {
                if let startedAt = recorder.startedAt {
                    discardButton
                    recordingLabel(since: startedAt)
                } else {
                    photoPicker
                    field
                }

                if hasContent {
                    sendButton
                } else {
                    micButton
                }
            }
            if text.count > Self.maxLength - 200 {
                Text("\(text.count) / \(Self.maxLength)")
                    .font(.caption)
                    .foregroundStyle(text.count > Self.maxLength ? Color.red : Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        .onChange(of: pickedPhotos) { _, items in
            add(items)
        }
    }

    // MARK: - Parts

    private var photoPicker: some View {
        PhotosPicker(
            selection: $pickedPhotos,
            maxSelectionCount: max(1, DraftAttachment.maxCount - attachments.count),
            matching: .images
        ) {
            CircleIcon(systemName: "plus", foreground: Color.primary, background: Color(.secondarySystemBackground))
        }
        .disabled(attachments.count >= DraftAttachment.maxCount)
        .accessibilityLabel("Add photos")
    }

    private var field: some View {
        TextField("Message", text: $text, axis: .vertical)
            .lineLimit(1...6)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func recordingLabel(since start: Date) -> some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red).frame(width: 8, height: 8)
            Text("Recording")
            Text(start, style: .timer).monospacedDigit().foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var sendButton: some View {
        Button(action: sendDraft) {
            Image(systemName: "arrow.up")
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.tint, in: Circle())
        }
        .disabled(text.count > Self.maxLength)
        .accessibilityLabel("Send")
    }

    private var micButton: some View {
        Button(action: toggleRecording) {
            if recorder.isRecording {
                CircleIcon(systemName: "arrow.up", foreground: Color.white, background: Color.red)
            } else {
                CircleIcon(systemName: "mic", foreground: Color.primary, background: Color(.secondarySystemBackground))
            }
        }
        .accessibilityLabel(recorder.isRecording ? "Send voice note" : "Record a voice note")
    }

    private var discardButton: some View {
        Button {
            recorder.cancel()
        } label: {
            CircleIcon(systemName: "xmark", foreground: Color.primary, background: Color(.secondarySystemBackground))
        }
        .accessibilityLabel("Discard voice note")
    }

    private var attachmentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { attachment in
                    preview(of: attachment)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                attachments.removeAll { $0.id == attachment.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.white, Color.black.opacity(0.6))
                                    .font(.title3)
                            }
                            .padding(3)
                            .accessibilityLabel("Remove")
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func preview(of attachment: DraftAttachment) -> some View {
        if let thumbnail = attachment.thumbnail {
            Image(uiImage: thumbnail).resizable().scaledToFill()
        } else {
            Color(.secondarySystemBackground)
                .overlay {
                    Image(systemName: "waveform").font(.title2).foregroundStyle(.secondary)
                }
        }
    }

    private var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    // MARK: - Actions

    private func sendDraft() {
        send(text, attachments)
    }

    private func send(_ message: String, _ files: [DraftAttachment]) {
        text = ""
        attachments = []
        Task {
            let sent = await onSend(message, files.map(\.upload))
            // On failure the SDK has already removed the message from the
            // list; put it back in the composer, unless something new is there.
            if !sent && text.isEmpty && attachments.isEmpty {
                text = message
                attachments = files
            }
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            if let note = recorder.stop() {
                send("", [.voiceNote(note)])
            }
        } else {
            Task {
                do {
                    try await recorder.start()
                } catch {
                    onError(error)
                }
            }
        }
    }

    private func add(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        // Cleared so picking the same photo again still counts as a change.
        pickedPhotos = []
        Task {
            for item in items where attachments.count < DraftAttachment.maxCount {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let photo = DraftAttachment.photo(from: data) else { continue }
                    attachments.append(photo)
                } catch {
                    onError(error)
                }
            }
        }
    }
}

/// A round icon button face. A View of its own rather than a method on
/// Composer: PhotosPicker builds its label outside the main actor, and a
/// struct's memberwise init can be called from there, a Composer method can't.
private struct CircleIcon: View {
    let systemName: String
    let foreground: Color
    let background: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(width: 36, height: 36)
            .background(background, in: Circle())
    }
}
