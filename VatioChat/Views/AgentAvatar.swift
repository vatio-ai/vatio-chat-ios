import SwiftUI

/// The agent's picture when it has one, else its initial on the accent color,
/// else a generic glyph while the config hasn't loaded.
struct AgentAvatar: View {
    let name: String?
    let url: URL?
    var size: CGFloat = 40

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    placeholder
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(.tint)
            .frame(width: size, height: size)
            .overlay {
                if let initial {
                    Text(initial)
                        .font(.system(size: size * 0.45, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: size * 0.45))
                        .foregroundStyle(.white)
                }
            }
    }

    private var initial: String? {
        name?.first.map { String($0).uppercased() }
    }
}
