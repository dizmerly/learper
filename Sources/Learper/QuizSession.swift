import Foundation

struct QuizSession {
    let quizSet: QuizSet
    private(set) var questionIndex = 0
    private(set) var selectedChoiceID: String?
    private(set) var answers: [String: String] = [:]
    private(set) var revealedHintCount = 0
    private(set) var showingResults = false

    var question: QuizQuestion { quizSet.questions[questionIndex] }
    var hasSubmitted: Bool { answers[question.id] != nil }
    var isLastQuestion: Bool { questionIndex == quizSet.questions.count - 1 }
    var correctCount: Int {
        quizSet.questions.filter { answers[$0.id] == $0.correctAnswerId }.count
    }

    mutating func select(_ id: String) {
        guard !hasSubmitted, question.choices.contains(where: { $0.id == id }) else { return }
        selectedChoiceID = id
    }

    mutating func revealHint() {
        revealedHintCount = min(revealedHintCount + 1, question.hints.count)
    }

    mutating func submit() {
        guard !hasSubmitted, let selectedChoiceID else { return }
        answers[question.id] = selectedChoiceID
    }

    mutating func advance() {
        guard hasSubmitted else { return }
        if isLastQuestion {
            showingResults = true
        } else {
            questionIndex += 1
            selectedChoiceID = nil
            revealedHintCount = 0
        }
    }

    mutating func restart() { self = QuizSession(quizSet: quizSet) }
}
