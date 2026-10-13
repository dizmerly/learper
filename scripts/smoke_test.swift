import Foundation

@main
enum SmokeTest {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Pass the sample quiz JSON path")
        }
        let sampleData = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let quiz = try QuizCodec.decode(sampleData)
        precondition(quiz.questions.count == 3)
        precondition(quiz.questions[0].correctChoice?.id == "b")

        var session = QuizSession(quizSet: quiz)
        session.revealHint()
        precondition(session.revealedHintCount == 1)
        session.select("b")
        session.submit()
        precondition(session.hasSubmitted && session.correctCount == 1)
        session.select("a")
        precondition(session.selectedChoiceID == "b")
        session.advance()
        precondition(session.questionIndex == 1 && session.revealedHintCount == 0)

        let temporary = FileManager.default.temporaryDirectory
            .appendingPathComponent("Learper-smoke-\(UUID().uuidString)")
            .appendingPathComponent("library.json")
        defer { try? FileManager.default.removeItem(at: temporary.deletingLastPathComponent()) }

        let library = QuizLibrary(storageURL: temporary)
        try library.importData(sampleData)
        precondition(library.sets.count == 1)
        try library.importData(sampleData)
        precondition(library.sets.count == 1, "Matching IDs should replace the set")
        let reopened = QuizLibrary(storageURL: temporary)
        precondition(reopened.sets.first == quiz)

        let badJSON = sampleDataString(sampleData).replacingOccurrences(
            of: "\"correctAnswerId\": \"b\"",
            with: "\"correctAnswerId\": \"missing\""
        )
        precondition(badJSON != sampleDataString(sampleData))
        do {
            _ = try QuizCodec.decode(Data(badJSON.utf8))
            fatalError("Invalid answer ID was accepted")
        } catch QuizError.invalid { }

        print("Learper smoke checks passed")
    }

    private static func sampleDataString(_ data: Data) -> String {
        String(decoding: data, as: UTF8.self)
    }
}
