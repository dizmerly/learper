import Foundation
#if LEARPER_MANUAL_TEST_RUNNER
import LearperTestSupport
#else
import XCTest
#endif
@testable import Learper

final class QuizModelsTests: XCTestCase {
    func testSampleDecodesAndRoundTripsRichContent() throws {
        let set = try TestFixtures.sampleSet()
        XCTAssertEqual(set.questions.count, 3)
        XCTAssertEqual(set.questions[0].correctChoice?.id, "b")
        XCTAssertTrue(set.questions[0].question.contains("$f(x)"))
        XCTAssertTrue(set.questions[1].description?.contains("```python") == true)
        let roundTrip = try QuizCodec.decode(QuizCodec.encode(set))
        XCTAssertEqual(roundTrip, set)
    }

    func testRejectsUnsupportedVersionAndEmptySetFields() {
        assertInvalid(TestFixtures.set(version: 2), contains: "version")
        assertInvalid(TestFixtures.set(id: "  "), contains: "id and title")
        assertInvalid(TestFixtures.set(title: "\n"), contains: "id and title")
        assertInvalid(TestFixtures.set(questions: []), contains: "at least one")
    }

    func testRejectsDuplicateQuestionIDsAndMissingQuestionText() {
        let repeated = TestFixtures.question(id: "same")
        assertInvalid(TestFixtures.set(questions: [repeated, repeated]), contains: "more than once")
        assertInvalid(
            TestFixtures.set(questions: [TestFixtures.question(text: " ")]),
            contains: "question, and explanation"
        )
        assertInvalid(
            TestFixtures.set(questions: [TestFixtures.question(explanation: "")]),
            contains: "question, and explanation"
        )
    }

    func testRejectsChoiceCountDuplicateIDsAndBadAnswer() {
        let one = [AnswerChoice(id: "a", text: "Only one")]
        assertInvalid(TestFixtures.set(questions: [TestFixtures.question(choices: one)]), contains: "2 and 6")

        let seven = (0..<7).map { AnswerChoice(id: "\($0)", text: "Choice \($0)") }
        assertInvalid(TestFixtures.set(questions: [TestFixtures.question(choices: seven)]), contains: "2 and 6")

        let duplicated = [AnswerChoice(id: "a", text: "One"), AnswerChoice(id: "a", text: "Two")]
        assertInvalid(TestFixtures.set(questions: [TestFixtures.question(choices: duplicated)]), contains: "repeats choice")

        let blank = [AnswerChoice(id: "a", text: "One"), AnswerChoice(id: "b", text: " ")]
        assertInvalid(TestFixtures.set(questions: [TestFixtures.question(choices: blank)]), contains: "empty choice")

        assertInvalid(
            TestFixtures.set(questions: [TestFixtures.question(answer: "missing")]),
            contains: "correctAnswerId"
        )
    }

    func testRejectsMalformedJSONAndMissingRequiredHints() throws {
        XCTAssertThrowsError(try QuizCodec.decode(Data("not json".utf8)))

        let rawObject = try JSONSerialization.jsonObject(with: TestFixtures.sampleData())
        let object = try XCTUnwrap(rawObject as? [String: Any])
        var changed = object
        var questions = try XCTUnwrap(changed["questions"] as? [[String: Any]])
        questions[0].removeValue(forKey: "hints")
        changed["questions"] = questions
        let data = try JSONSerialization.data(withJSONObject: changed)
        XCTAssertThrowsError(try QuizCodec.decode(data))
    }

    func testAcceptsReservedImageMetadataWithoutRequiringIt() throws {
        let image = QuestionImage(url: "https://example.invalid/diagram.png", alt: "Diagram")
        let question = TestFixtures.question()
        let withImage = QuizQuestion(
            id: question.id,
            question: question.question,
            description: question.description,
            hints: question.hints,
            choices: question.choices,
            correctAnswerId: question.correctAnswerId,
            explanation: question.explanation,
            image: image
        )
        let set = TestFixtures.set(questions: [withImage])
        let decoded = try QuizCodec.decode(QuizCodec.encode(set))
        XCTAssertEqual(decoded.questions[0].image, image)
    }

    func testShortAnswerDecodesWithoutChoicesAndKeepsLegacyMCQ() throws {
        let json = #"{"version":1,"id":"saq","title":"Written","type":"saq","questions":[{"id":"q1","question":"Explain photosynthesis.","hints":[],"explanation":"Mention light, water, and carbon dioxide."}]}"#
        let set = try QuizCodec.decode(Data(json.utf8))
        XCTAssertEqual(set.type, .saq)
        XCTAssertTrue(set.questions[0].choices.isEmpty)
        let roundTrip = try QuizCodec.decode(QuizCodec.encode(set))
        XCTAssertEqual(roundTrip, set)
        let sample = try TestFixtures.sampleSet()
        XCTAssertEqual(sample.type, .mcq)
        XCTAssertThrowsError(try QuizSet(version: 1, id: "bad", title: "Bad", description: nil,
                                         questions: [TestFixtures.question()], type: .saq).validate())
    }

    private func assertInvalid(
        _ set: QuizSet,
        contains expectedText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try set.validate(), file: file, line: line) { error in
            XCTAssertTrue(error.localizedDescription.contains(expectedText), "\(error)", file: file, line: line)
        }
    }
}
