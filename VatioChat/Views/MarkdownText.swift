import SwiftUI

/// Renders an agent's reply as Markdown.
///
/// SwiftUI's `Text` only understands inline Markdown, so the blocks
/// (paragraphs, headings, lists, code blocks, quotes) are parsed here, line by
/// line, and each block's inline styling (bold, italic, inline code, links)
/// comes from `AttributedString`. Replies are untrusted text: nothing is read
/// as HTML, and only web, mail and phone links stay tappable.
struct MarkdownText: View {
    private let blocks: [MarkdownBlock]

    init(_ markdown: String) {
        blocks = MarkdownBlock.parse(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(blocks.indices, id: \.self) { index in
                view(for: blocks[index])
            }
        }
    }

    @ViewBuilder
    private func view(for block: MarkdownBlock) -> some View {
        switch block {
        case .paragraph(let text):
            Text(Self.inline(text))
        case .heading(let level, let text):
            Text(Self.inline(text)).font(Self.headingFont(level))
        case .listItem(let marker, let depth, let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(marker).monospacedDigit()
                Text(Self.inline(text))
            }
            .padding(.leading, CGFloat(depth) * 18)
        case .code(let code):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.callout, design: .monospaced))
                    .padding(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        case .quote(let text):
            Text(Self.inline(text))
                .foregroundStyle(.secondary)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    Rectangle().fill(.quaternary).frame(width: 3)
                }
        case .divider:
            Divider()
        }
    }

    private static func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title2.bold()
        case 2: return .title3.bold()
        default: return .headline
        }
    }

    private static let safeSchemes: Set<String> = ["http", "https", "mailto", "tel"]

    /// Bold, italic, inline code and links within one block. Whitespace is
    /// kept, so a single line break in a reply stays a line break.
    private static func inline(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let parsed = (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)

        // Rebuilt run by run rather than edited in place, so no index is
        // used after the string it came from has changed.
        var result = AttributedString()
        for run in parsed.runs {
            var piece = AttributedString(parsed[run.range])
            if let url = run.link, !safeSchemes.contains(url.scheme?.lowercased() ?? "") {
                piece.link = nil
            }
            result.append(piece)
        }
        return result
    }
}

/// One block of a Markdown reply.
enum MarkdownBlock: Equatable {
    case paragraph(String)
    case heading(level: Int, text: String)
    /// `marker` is "•" for a bullet, or the number with its dot.
    case listItem(marker: String, depth: Int, text: String)
    case code(String)
    case quote(String)
    case divider

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var codeLines: [String] = []
        var isInCode = false

        func endParagraph() {
            guard !paragraph.isEmpty else { return }
            blocks.append(.paragraph(paragraph.joined(separator: "\n")))
            paragraph = []
        }

        for line in markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if isInCode {
                if trimmed.hasPrefix("```") {
                    blocks.append(.code(codeLines.joined(separator: "\n")))
                    codeLines = []
                    isInCode = false
                } else {
                    codeLines.append(line)
                }
                continue
            }

            if trimmed.hasPrefix("```") {
                endParagraph()
                isInCode = true
            } else if trimmed.isEmpty {
                endParagraph()
            } else if let heading = parseHeading(trimmed) {
                endParagraph()
                blocks.append(heading)
            } else if isDivider(trimmed) {
                endParagraph()
                blocks.append(.divider)
            } else if let item = parseListItem(line) {
                endParagraph()
                blocks.append(item)
            } else if trimmed.hasPrefix(">") {
                endParagraph()
                let text = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                if case .quote(let previous)? = blocks.last {
                    blocks[blocks.count - 1] = .quote(previous + "\n" + text)
                } else {
                    blocks.append(.quote(text))
                }
            } else if paragraph.isEmpty, line.first?.isWhitespace == true,
                      case .listItem(let marker, let depth, let text)? = blocks.last {
                // An indented line right after a list item continues it.
                blocks[blocks.count - 1] = .listItem(marker: marker, depth: depth, text: text + "\n" + trimmed)
            } else {
                paragraph.append(trimmed)
            }
        }

        endParagraph()
        // A reply that never closed its code fence still shows the code.
        if isInCode { blocks.append(.code(codeLines.joined(separator: "\n"))) }
        return blocks
    }

    /// `# Title` to `###### Title`.
    private static func parseHeading(_ line: String) -> MarkdownBlock? {
        let level = line.prefix(while: { $0 == "#" }).count
        let rest = line.dropFirst(level)
        guard (1...6).contains(level), rest.first == " " else { return nil }
        return .heading(level: level, text: rest.trimmingCharacters(in: .whitespaces))
    }

    /// `---`, `***` or `___`.
    private static func isDivider(_ line: String) -> Bool {
        let marks = line.filter { $0 != " " }
        guard marks.count >= 3, let first = marks.first, "-*_".contains(first) else { return false }
        return marks.allSatisfy { $0 == first }
    }

    /// `- item`, `* item`, `+ item`, `1. item` or `1) item`, indented two
    /// spaces per level.
    private static func parseListItem(_ line: String) -> MarkdownBlock? {
        let indent = line.prefix(while: { $0 == " " || $0 == "\t" })
        let width = indent.reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }
        let depth = min(width / 2, 3)
        let body = line.dropFirst(indent.count)

        if let bullet = body.first, "-*+".contains(bullet), body.dropFirst().first == " " {
            return .listItem(marker: "•", depth: depth, text: body.dropFirst(2).trimmingCharacters(in: .whitespaces))
        }

        let digits = body.prefix(while: { $0 >= "0" && $0 <= "9" })
        let afterDigits = body.dropFirst(digits.count)
        guard !digits.isEmpty, digits.count <= 9,
              let delimiter = afterDigits.first, delimiter == "." || delimiter == ")",
              afterDigits.dropFirst().first == " " else { return nil }
        return .listItem(marker: "\(digits).", depth: depth, text: afterDigits.dropFirst(2).trimmingCharacters(in: .whitespaces))
    }
}
