import Foundation

enum QuizDifficulty: String, CaseIterable, Identifiable {
    case introductory = "Introductory"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case mixed = "Mixed"

    var id: Self { self }
}

enum QuizPrompt {
    static let formatDocument: String? = {
        guard let url = QuizResources.bundle.url(forResource: "QUESTION_FORMAT", withExtension: "md") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }()

    static func make(
        topic: String,
        questionCount: Int,
        difficulty: QuizDifficulty,
        format: String
    ) -> String {
        format
            .replacingOccurrences(of: "[number]", with: String(questionCount))
            .replacingOccurrences(of: "[difficulty]", with: difficulty.rawValue.lowercased())
            .replacingOccurrences(of: "[topic or supplied notes]", with: topic.trimmed)
    }
}
