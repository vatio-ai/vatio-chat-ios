import UIKit
import Vatio

/// A file waiting in the composer: what will be uploaded, and a thumbnail to
/// show above the text field until then.
struct DraftAttachment: Identifiable {
    let id = UUID()
    let upload: VatioUpload
    /// Nil for a voice note.
    let thumbnail: UIImage?

    static let maxCount = 4

    /// Photos go up as JPEG, at most 2048 px on the long side: one format the
    /// agent always reads, well under the 8 MB limit, and quick to upload
    /// from a phone. Nil when the data isn't an image UIKit can read.
    static func photo(from data: Data) -> DraftAttachment? {
        guard let image = UIImage(data: data) else { return nil }

        let longest = max(image.size.width, image.size.height)
        let scale = min(1, 2048 / max(longest, 1))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        // Drawing also applies the photo's orientation, so the JPEG is upright.
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        guard let jpeg = resized.jpegData(compressionQuality: 0.8) else { return nil }
        return DraftAttachment(
            upload: VatioUpload(data: jpeg, filename: "photo.jpg", contentType: "image/jpeg"),
            thumbnail: resized
        )
    }

    static func voiceNote(_ upload: VatioUpload) -> DraftAttachment {
        DraftAttachment(upload: upload, thumbnail: nil)
    }
}
