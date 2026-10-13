import Foundation

struct QuestionOutcome: Identifiable {
    let number: Int
    let question: QuizQuestion
    let selectedChoice: AnswerChoice

    var id: String { question.id }
    var isCorrect: Bool { selectedChoice.id == question.correctAnswerId }
    var correctChoice: AnswerChoice? { question.correctChoice }
}

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
    var outcomes: [QuestionOutcome] {
        quizSet.questions.enumerated().compactMap { index, question in
            guard let answerID = answers[question.id],
                  let choice = question.choices.first(where: { $0.id == answerID }) else { return nil }
            return QuestionOutcome(number: index + 1, question: question, selectedChoice: choice)
        }
    }
    var correctCount: Int { outcomes.filter(\.isCorrect).count }
    var missedOutcomes: [QuestionOutcome] { outcomes.filter { !$0.isCorrect } }
    var accuracyPercent: Int {
        guard !outcomes.isEmpty else { return 0 }
        return Int((Double(correctCount) / Double(outcomes.count) * 100).rounded())
    }

    mutating func select(_ id: String) {
        guard !hasSubmitted, question.choices.contains(where: { $0.id == id }) else { return }
        selectedChoiceID = id
    }

    mutating func selectChoice(number: Int) {
        guard (1...4).contains(number), number <= question.choices.count else { return }
        select(question.choices[number - 1].id)
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

    mutating func primaryAction() {
        guard !showingResults else { return }
        if hasSubmitted { advance() } else { submit() }
    }

    mutating func restart() { self = QuizSession(quizSet: quizSet) }
}
