import Foundation
#if LEARPER_MANUAL_TEST_RUNNER
import LearperTestSupport
#else
import XCTest
#endif
@testable import Learper

final class QuizSessionTests: XCTestCase {
    func testCannotSubmitOrAdvanceWithoutAnswer() throws {
        var session = QuizSession(quizSet: try TestFixtures.sampleSet())
        session.submit()
        session.advance()
        XCTAssertFalse(session.hasSubmitted)
        XCTAssertEqual(session.questionIndex, 0)

        session.select("not-a-choice")
        XCTAssertNil(session.selectedChoiceID)
    }

    func testHintsStopAtAvailableCountAndResetOnNextQuestion() throws {
        var session = QuizSession(quizSet: try TestFixtures.sampleSet())
        for _ in 0..<5 { session.revealHint() }
        XCTAssertEqual(session.revealedHintCount, 2)

        session.select("b")
        session.submit()
        session.advance()
        XCTAssertEqual(session.questionIndex, 1)
        XCTAssertEqual(session.revealedHintCount, 0)
        XCTAssertNil(session.selectedChoiceID)
    }

    func testWrongAnswerLocksSelectionAndCountsCorrectly() throws {
        var session = QuizSession(quizSet: try TestFixtures.sampleSet())
        session.select("a")
        session.submit()
        XCTAssertTrue(session.hasSubmitted)
        XCTAssertEqual(session.correctCount, 0)
        session.select("b")
        session.submit()
        XCTAssertEqual(session.selectedChoiceID, "a")
        XCTAssertEqual(session.answers[session.question.id], "a")
    }

    func testCompletionAndRetry() throws {
        var session = QuizSession(quizSet: try TestFixtures.sampleSet())
        let answers = ["b", "b", "c"]
        for (index, answer) in answers.enumerated() {
            session.select(answer)
            session.submit()
            XCTAssertEqual(session.correctCount, index + 1)
            session.advance()
        }
        XCTAssertTrue(session.showingResults)
        XCTAssertEqual(session.correctCount, 3)
        XCTAssertTrue(session.isLastQuestion)

        session.restart()
        XCTAssertEqual(session.questionIndex, 0)
        XCTAssertEqual(session.correctCount, 0)
        XCTAssertFalse(session.hasSubmitted)
        XCTAssertFalse(session.showingResults)
        XCTAssertTrue(session.answers.isEmpty)
    }
}
