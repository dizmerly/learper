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
        type: QuizType = .mcq,
        includeMultipleSelect: Bool = false,
        format: String
    ) -> String {
        let selectionInstruction = type == .saq ? "" : includeMultipleSelect
            ? "Include select-all-that-apply questions with two or more correct choices alongside single-answer questions."
            : "Use single-answer questions only."
        return format
            .replacingOccurrences(of: "[number]", with: String(questionCount))
            .replacingOccurrences(of: "[difficulty]", with: difficulty.rawValue.lowercased())
            .replacingOccurrences(of: "[quiz type]", with: type == .mcq ? "multiple-choice" : "short-answer")
            .replacingOccurrences(of: "[quiz type id]", with: type.rawValue)
            .replacingOccurrences(of: "[topic or supplied notes]", with: topic.trimmed)
            .replacingOccurrences(of: "[selection instruction]", with: selectionInstruction)
    }
}
