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
        session.rateCurrent(.moderate, updatedWeight: 0.85)
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
            session.rateCurrent(.moderate, updatedWeight: 0.85)
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
        session.rateCurrent(.moderate, updatedWeight: 0.85)
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
            session.rateCurrent(.hard, updatedWeight: 1.5)
            session.primaryAction()
        }

        XCTAssertTrue(session.showingResults)
        XCTAssertEqual(session.outcomes.count, 3)
        XCTAssertEqual(session.correctCount, 2)
        XCTAssertEqual(session.missedOutcomes.count, 1)
        XCTAssertEqual(session.accuracyPercent, 67)
        XCTAssertEqual(session.missedOutcomes[0].number, 1)
        XCTAssertEqual(session.missedOutcomes[0].selectedChoices.map(\.id), ["a"])
        XCTAssertEqual(session.missedOutcomes[0].question.correctChoice?.id, "b")

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
        session.rateCurrent(.moderate, updatedWeight: 0.85)
        session.advance()
        session.updateDraft("An apple falling.")
        session.primaryAction()
        session.rateCurrent(.easy, updatedWeight: 0.6)
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

    func testRatingsChangeWeightAndGateAdvancement() throws {
        XCTAssertEqual(PracticeRating.easy.updatedWeight(from: 1), 0.6)
        XCTAssertEqual(PracticeRating.moderate.updatedWeight(from: 1), 0.85)
        XCTAssertEqual(PracticeRating.hard.updatedWeight(from: 1), 1.5)
        XCTAssertEqual(PracticeRating.impossible.updatedWeight(from: 1), 2)
        XCTAssertEqual(PracticeRating.impossible.updatedWeight(from: 4), 5)
        XCTAssertEqual(PracticeRating.easy.updatedWeight(from: 0.25), 0.25)

        var session = QuizSession(quizSet: try TestFixtures.sampleSet())
        session.select("b")
        session.submit()
        session.advance()
        XCTAssertEqual(session.questionIndex, 0)
        session.rateCurrent(.hard, updatedWeight: 1.5)
        session.advance()
        XCTAssertEqual(session.questionIndex, 1)
    }

    func testFolderPracticeCoversUnknownCardsAndCopiesWeightedResults() throws {
        let group = QuizGroup(id: "g", name: "Science")
        let mcq = QuizSet(version: 1, id: "mcq", title: "Choices", description: nil,
                          questions: [TestFixtures.question(id: "same")], groupID: group.id)
        let saq = QuizSet(version: 1, id: "saq", title: "Written", description: nil,
                          questions: [QuizQuestion(id: "same", question: "Explain it.", hints: [])],
                          type: .saq, groupID: group.id)
        var session = try XCTUnwrap(QuizSession(group: group, sets: [mcq, saq]))
        XCTAssertEqual(session.quizSet.questionCount, 2)
        XCTAssertEqual(Set(session.quizSet.questions.map(\.id)).count, 2)
        var seen = Set<String>()
        for _ in 0..<2 {
            seen.insert(session.currentSource.setID)
            if session.currentType == .mcq { session.select("b") }
            else { session.updateDraft("My written response") }
            session.submit()
            session.rateCurrent(.hard, updatedWeight: 1.5)
            session.advance()
        }
        XCTAssertEqual(seen, Set(["mcq", "saq"]))
        XCTAssertTrue(session.showingResults)
        XCTAssertTrue(session.resultsPrompt.contains("Higher weights"))
        XCTAssertTrue(session.resultsPrompt.contains("Updated weight: 1.5"))
        XCTAssertTrue(session.resultsPrompt.contains("Choices"))
        XCTAssertTrue(session.resultsPrompt.contains("Written"))

        var hardQuestion = TestFixtures.question(id: "hard")
        hardQuestion.weight = 5
        let weighted = QuizSet(version: 1, id: "weighted", title: "Weighted", description: nil,
                               questions: [hardQuestion], groupID: group.id)
        let next = try XCTUnwrap(QuizSession(group: group, sets: [weighted, mcq]))
        XCTAssertTrue(next.quizSet.questionCount > 2)
        XCTAssertEqual(next.hardestQuestionIndices.count, 2)
        let hardestIndex = try XCTUnwrap(next.hardestQuestionIndices.first)
        XCTAssertEqual(next.sourceTitle(at: hardestIndex), "Weighted")
    }

    func testMultipleSelectionTogglesAndGradesExactSet() throws {
        let choices = [AnswerChoice(id: "a", text: "Two"), AnswerChoice(id: "b", text: "Three"),
                       AnswerChoice(id: "c", text: "Four")]
        let multi = QuizQuestion(id: "multi", question: "Which are even?", hints: [], choices: choices,
                                 correctAnswerIds: ["a", "c"], explanation: "Two and four are even.")
        let set = TestFixtures.set(questions: [multi, TestFixtures.question(id: "single")])
        var session = QuizSession(quizSet: set)
        session.select("a")
        session.select("c")
        XCTAssertEqual(session.selectedChoiceIDs, Set(["a", "c"]))
        session.select("c")
        XCTAssertEqual(session.selectedChoiceIDs, Set(["a"]))
        session.select("c")
        session.select("b")
        session.submit()
        XCTAssertFalse(session.currentAnswerIsCorrect)
        XCTAssertEqual(session.missedOutcomes.count, 1)
        XCTAssertEqual(session.answerText(at: 0), "Two; Three; Four")
        session.rateCurrent(.hard, updatedWeight: 1.5)
        session.advance()
        session.select("b")
        session.submit()
        XCTAssertTrue(session.currentAnswerIsCorrect)
        session.rateCurrent(.easy, updatedWeight: 0.6)
        session.advance()
        XCTAssertEqual(session.correctCount, 1)
        XCTAssertTrue(session.resultsPrompt.contains("Correct answer: Two; Four"))

        var exact = QuizSession(quizSet: set)
        exact.select("a")
        exact.select("c")
        exact.submit()
        XCTAssertTrue(exact.currentAnswerIsCorrect)
        XCTAssertEqual(exact.correctCount, 1)
    }

    func testUnknownAnswerAppearsInResultsAndCannotBeChanged() throws {
        let choices = [AnswerChoice(id: "a", text: "Two"), AnswerChoice(id: "b", text: "Three"),
                       AnswerChoice(id: "c", text: "Four")]
        let multi = QuizQuestion(id: "multi", question: "Which are even?", hints: [], choices: choices,
                                 correctAnswerIds: ["a", "c"], explanation: "Two and four are even.")
        var session = QuizSession(quizSet: TestFixtures.set(questions: [multi]))
        session.select("a")
        session.submitUnknown()
        XCTAssertTrue(session.hasSubmitted)
        XCTAssertTrue(session.currentAnswerIsUnknown)
        XCTAssertFalse(session.currentAnswerIsCorrect)
        XCTAssertTrue(session.selectedChoiceIDs.isEmpty)
        session.select("c")
        session.submit()
        XCTAssertTrue(session.selectedChoiceIDs.isEmpty)
        XCTAssertEqual(session.answerText(at: 0), "I don't know")
        XCTAssertEqual(session.missedOutcomes.count, 1)
        XCTAssertTrue(session.missedOutcomes[0].didNotKnow)
        session.rateCurrent(.impossible, updatedWeight: 2)
        session.advance()
        XCTAssertTrue(session.showingResults)
        XCTAssertTrue(session.resultsPrompt.contains("Student answer: I don't know"))
        session.restart()
        XCTAssertFalse(session.currentAnswerIsUnknown)
    }

    func testQuestionNavigationPreservesDraftsAndSubmittedAnswers() throws {
        var session = QuizSession(quizSet: try TestFixtures.sampleSet())
        session.select("a")
        session.revealHint()
        session.navigate(to: 2)
        XCTAssertFalse(session.isAnswered(at: 0))
        session.select("c")
        session.submit()
        session.rateCurrent(.easy, updatedWeight: 0.6)
        session.advance()
        XCTAssertFalse(session.showingResults)
        XCTAssertEqual(session.questionIndex, 0)
        XCTAssertEqual(session.selectedChoiceID, "a")
        XCTAssertEqual(session.revealedHintCount, 1)
        session.navigate(to: 2)
        XCTAssertTrue(session.hasSubmitted)
        XCTAssertEqual(session.selectedChoiceID, "c")
        XCTAssertTrue(session.currentAnswerIsCorrect)
        XCTAssertEqual(session.currentRating, .easy)
        session.navigate(to: -1)
        session.navigate(to: 3)
        XCTAssertEqual(session.questionIndex, 2)
        session.navigate(to: 0)
        session.submit()
        session.rateCurrent(.hard, updatedWeight: 1.5)
        session.advance()
        session.select("b")
        session.submit()
        session.rateCurrent(.easy, updatedWeight: 0.6)
        session.advance()
        XCTAssertTrue(session.showingResults)

        let written = QuizSet(version: 1, id: "written", title: "Written", description: nil,
                              questions: [QuizQuestion(id: "one", question: "Explain.", hints: []),
                                          QuizQuestion(id: "two", question: "Describe.", hints: [])], type: .saq)
        var shortAnswer = QuizSession(quizSet: written)
        shortAnswer.updateDraft("Unfinished thought")
        shortAnswer.navigate(to: 1)
        shortAnswer.navigate(to: 0)
        XCTAssertEqual(shortAnswer.draftAnswer, "Unfinished thought")
        XCTAssertFalse(shortAnswer.hasSubmitted)
    }

    func testQuestionDotsSlideWithinTenQuestionWindow() throws {
        let questions = (0..<23).map { TestFixtures.question(id: "q\($0)") }
        var session = QuizSession(quizSet: TestFixtures.set(questions: questions))
        XCTAssertEqual(Array(session.visibleQuestionIndices), Array(0..<10))
        session.navigate(to: 12)
        XCTAssertEqual(Array(session.visibleQuestionIndices), Array(8..<18))
        session.submitUnknown()
        XCTAssertTrue(session.isAnswered(at: 12))
        session.navigate(to: 22)
        XCTAssertEqual(Array(session.visibleQuestionIndices), Array(13..<23))
        XCTAssertFalse(session.isAnswered(at: 22))
    }
}
