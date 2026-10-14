import Foundation

enum RichTextRendering {
    /// Be conservative: ambiguous Markdown stays with the full renderer.
    static func needsWebView(_ source: String) -> Bool {
        if source.rangeOfCharacter(from: markupCharacters) != nil { return true }
        return source.range(of: #"^(?: {4}|\t|\s*\d+[.)]\s)"#, options: .regularExpression) != nil
    }

    private static let markupCharacters = CharacterSet(charactersIn: "*_`$~[]<>\\#\n\r&-+=")
}
