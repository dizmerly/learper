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
        XCTAssertTrue(session.missedOutcomes.isEmpty)
        XCTAssertEqual(session.accuracyPercent, 100)
        XCTAssertTrue(session.isLastQuestion)

        session.restart()
        XCTAssertEqual(session.questionIndex, 0)
        XCTAssertEqual(session.correctCount, 0)
        XCTAssertFalse(session.hasSubmitted)
        XCTAssertFalse(session.showingResults)
        XCTAssertTrue(session.answers.isEmpty)
    }

    func testNumberKeysAndSpaceActionFollowQuizState() throws {
        var session = QuizSession(quizSet: try TestFixtures.sampleSet())
        session.primaryAction()
        XCTAssertFalse(session.hasSubmitted)

        session.selectChoice(number: 5)
        XCTAssertNil(session.selectedChoiceID)
        for (number, id) in [(1, "a"), (2, "b"), (3, "c"), (4, "d")] {
            session.selectChoice(number: number)
            XCTAssertEqual(session.selectedChoiceID, id)
        }
        session.selectChoice(number: 2)
        XCTAssertEqual(session.selectedChoiceID, "b")
        session.primaryAction()
        XCTAssertTrue(session.hasSubmitted)
        XCTAssertEqual(session.correctCount, 1)

        session.selectChoice(number: 1)
        XCTAssertEqual(session.selectedChoiceID, "b")
        session.primaryAction()
        XCTAssertEqual(session.questionIndex, 1)
        XCTAssertNil(session.selectedChoiceID)
    }

    func testStatisticsIdentifyMissedQuestionAndSelectedAnswer() throws {
        var session = QuizSession(quizSet: try TestFixtures.sampleSet())
        let answers = ["a", "b", "c"]
        for answer in answers {
            session.select(answer)
            session.primaryAction()
            session.primaryAction()
        }

        XCTAssertTrue(session.showingResults)
        XCTAssertEqual(session.outcomes.count, 3)
        XCTAssertEqual(session.correctCount, 2)
        XCTAssertEqual(session.missedOutcomes.count, 1)
        XCTAssertEqual(session.accuracyPercent, 67)
        XCTAssertEqual(session.missedOutcomes[0].number, 1)
        XCTAssertEqual(session.missedOutcomes[0].selectedChoice.id, "a")
        XCTAssertEqual(session.missedOutcomes[0].correctChoice?.id, "b")

        session.primaryAction()
        XCTAssertTrue(session.showingResults)
        session.restart()
        XCTAssertTrue(session.outcomes.isEmpty)
        XCTAssertEqual(session.accuracyPercent, 0)
    }

    func testShortAnswerCompletionAndGradingPrompt() throws {
        let questions = [
            QuizQuestion(id: "one", question: "Explain gravity.", hints: [], explanation: "Mention attraction."),
            QuizQuestion(id: "two", question: "Give an example.", hints: [])
        ]
        let set = QuizSet(version: 1, id: "written", title: "Physics", description: nil,
                          questions: questions, type: .saq)
        try set.validate()
        var session = QuizSession(quizSet: set)
        session.updateDraft("   ")
        session.submit()
        XCTAssertFalse(session.hasSubmitted)
        session.updateDraft("Masses attract each other.")
        session.submit()
        XCTAssertTrue(session.hasSubmitted)
        XCTAssertEqual(session.correctCount, 0)
        session.advance()
        session.updateDraft("An apple falling.")
        session.primaryAction()
        session.primaryAction()
        XCTAssertTrue(session.showingResults)
        XCTAssertTrue(session.gradingPrompt.contains("Question 1: Explain gravity."))
        XCTAssertTrue(session.gradingPrompt.contains("Student answer: Masses attract each other."))
        XCTAssertTrue(session.gradingPrompt.contains("Reference answer or grading guidance: Mention attraction."))
        XCTAssertTrue(session.gradingPrompt.contains("Question 2: Give an example."))
        session.restart()
        XCTAssertEqual(session.gradingPrompt, "")
        XCTAssertTrue(session.answers.isEmpty)
    }

    func testRenamingQuizKeepsSessionAnswers() throws {
        let original = try TestFixtures.sampleSet()
        var session = QuizSession(quizSet: original)
        session.select("b")
        session.submit()
        let renamed = QuizSet(version: original.version, id: original.id, title: "New name",
                              description: original.description, questions: original.questions, type: original.type)
        session.refreshMetadata(from: renamed)
        XCTAssertEqual(session.quizSet.title, "New name")
        XCTAssertEqual(session.correctCount, 1)
        XCTAssertTrue(session.hasSubmitted)
    }
}
