import Foundation
@testable import Learper

enum TestFixtures {
    static func sampleData() throws -> Data {
        if let path = ProcessInfo.processInfo.environment["LEARPER_SAMPLE_PATH"] {
            return try Data(contentsOf: URL(fileURLWithPath: path))
        }
        guard let url = QuizResources.bundle.url(forResource: "sample-quiz", withExtension: "json") else {
            throw QuizError.invalid("The bundled sample quiz is missing.")
        }
        return try Data(contentsOf: url)
    }

    static func sampleSet() throws -> QuizSet {
        try QuizCodec.decode(sampleData())
    }

    static func question(
        id: String = "q1",
        text: String = "Which choice is correct?",
        choices: [AnswerChoice] = [
            AnswerChoice(id: "a", text: "First"),
            AnswerChoice(id: "b", text: "Second")
        ],
        answer: String = "b",
        explanation: String = "The second choice is correct."
    ) -> QuizQuestion {
        QuizQuestion(
            id: id,
            question: text,
            description: nil,
            hints: ["Think it through."],
            choices: choices,
            correctAnswerId: answer,
            explanation: explanation,
            image: nil
        )
    }

    static func set(
        version: Int = 1,
        id: String = "test-set",
        title: String = "Test set",
        questions: [QuizQuestion] = [question()]
    ) -> QuizSet {
        QuizSet(version: version, id: id, title: title, description: nil, questions: questions)
    }

    static func temporaryLibraryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("LearperTests-\(UUID().uuidString)")
            .appendingPathComponent("library.json")
    }
}
