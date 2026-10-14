import AVFoundation
import Combine
import Vatio

/// Records a voice note as AAC in an .m4a file, one of the formats Vatio
/// transcribes. The agent reads the transcript, and the visitor sees it appear
/// on their message a few seconds after sending.
@MainActor
final class VoiceRecorder: ObservableObject {
    enum Failure: LocalizedError {
        case microphoneDenied
        case couldNotRecord

        var errorDescription: String? {
            switch self {
            case .microphoneDenied: return "Allow microphone access in the Settings app to send voice notes."
            case .couldNotRecord: return "The recording couldn't start."
            }
        }
    }

    /// When the current recording began; nil while not recording.
    @Published private(set) var startedAt: Date?
    var isRecording: Bool { startedAt != nil }

    private var recorder: AVAudioRecorder?
    private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("voice-note.m4a")

    /// Asks for the microphone the first time; the system shows
    /// `NSMicrophoneUsageDescription` from the Info.plist.
    func start() async throws {
        guard await AVAudioApplication.requestRecordPermission() else { throw Failure.microphoneDenied }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        guard recorder.record() else { throw Failure.couldNotRecord }
        self.recorder = recorder
        startedAt = Date()
    }

    /// Stops and returns the note to send. Nil for one under half a second,
    /// which is a double tap rather than something said.
    func stop() -> VatioUpload? {
        guard let recorder else { return nil }
        let duration = recorder.currentTime
        end(recorder)
        // The upload holds the bytes, so the file can go.
        defer { try? FileManager.default.removeItem(at: fileURL) }
        guard duration >= 0.5 else { return nil }
        return try? VatioUpload(fileURL: fileURL)
    }

    /// Stops and throws the recording away.
    func cancel() {
        guard let recorder else { return }
        end(recorder)
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func end(_ recorder: AVAudioRecorder) {
        recorder.stop()
        self.recorder = nil
        startedAt = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
