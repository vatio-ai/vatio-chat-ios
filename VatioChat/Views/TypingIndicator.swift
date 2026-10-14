import SwiftUI

/// Three dots that pulse in turn while `chat.isTyping`. Driven by the clock
/// rather than a repeating animation, so it looks the same however the list
/// around it scrolls or redraws.
struct TypingIndicator: View {
    var body: some View {
        TimelineView(.animation) { context in
            HStack(spacing: 5) {
                ForEach(0..<3) { dot in
                    Circle()
                        .frame(width: 8, height: 8)
                        .opacity(Self.opacity(of: dot, at: context.date))
                }
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
        }
        .accessibilityLabel("Typing")
    }

    /// Each dot brightens and fades once a second, a third of a cycle after
    /// the one before it.
    private static func opacity(of dot: Int, at date: Date) -> Double {
        let phase = date.timeIntervalSinceReferenceDate - Double(dot) / 3
        let wave = (sin(phase * 2 * .pi) + 1) / 2
        return 0.3 + 0.7 * wave
    }
}
