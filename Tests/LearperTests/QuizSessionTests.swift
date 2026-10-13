import Foundation
import XCTest
@testable import Learper

final class QuizSessionTests: XCTestCase {
    func testAnswerFlowAndRetry() throws {
        let url = try XCTUnwrap(QuizResources.bundle.url(forResource: "sample-quiz", withExtension: "json"))
        let set = try QuizCodec.decode(Data(contentsOf: url))
        var session = QuizSession(quizSet: set)

        session.revealHint()
        XCTAssertEqual(session.revealedHintCount, 1)
        session.select("b")
        session.submit()
        XCTAssertTrue(session.hasSubmitted)
        XCTAssertEqual(session.correctCount, 1)

        session.select("a")
        XCTAssertEqual(session.selectedChoiceID, "b")
        session.advance()
        XCTAssertEqual(session.questionIndex, 1)
        XCTAssertEqual(session.revealedHintCount, 0)

        session.restart()
        XCTAssertEqual(session.questionIndex, 0)
        XCTAssertEqual(session.correctCount, 0)
        XCTAssertFalse(session.hasSubmitted)
    }
}
