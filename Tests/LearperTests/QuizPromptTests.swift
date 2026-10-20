import Foundation
#if LEARPER_MANUAL_TEST_RUNNER
import LearperTestSupport
#else
import XCTest
#endif
@testable import Learper

final class QuizPromptTests: XCTestCase {
    func testGeneratedPromptIncludesCompleteFormatAndUserOptions() throws {
        let format = try bundledFormat()
        let prompt = QuizPrompt.make(
            topic: "  Rust ownership and borrowing  ",
            questionCount: 12,
            difficulty: .advanced,
            format: format
        )

        XCTAssertTrue(prompt.contains("Rust ownership and borrowing"))
        XCTAssertTrue(prompt.contains("**12** questions at **advanced**"))
        XCTAssertTrue(prompt.contains("downloadable UTF-8 file named `learper-quiz.json`"))
        XCTAssertTrue(prompt.contains("\"correctAnswerId\""))
        XCTAssertTrue(prompt.contains("\"correctAnswerIds\""))
        XCTAssertTrue(prompt.contains("Use single-answer questions only."))
        XCTAssertTrue(prompt.contains("\"explanation\""))
        XCTAssertTrue(prompt.contains("\"hints\""))
        XCTAssertTrue(prompt.contains("fenced `mermaid` blocks"))
        XCTAssertTrue(prompt.contains("LaTeX"))
        XCTAssertTrue(prompt.contains("does not fetch or display images"))
        XCTAssertTrue(prompt.contains("\"type\": \"mcq\""))
        XCTAssertTrue(prompt.contains("\"weight\": 1"))
        XCTAssertFalse(prompt.contains("[topic or supplied notes]"))
        XCTAssertFalse(prompt.contains("[number]"))
        XCTAssertFalse(prompt.contains("[difficulty]"))
    }

    func testShortAnswerPromptSelectsSAQFormat() throws {
        let prompt = QuizPrompt.make(topic: "Photosynthesis", questionCount: 4,
                                     difficulty: .mixed, type: .saq, format: try bundledFormat())
        XCTAssertTrue(prompt.contains("Create a Learper v1 short-answer quiz"))
        XCTAssertTrue(prompt.contains("\"type\": \"saq\""))
        XCTAssertTrue(prompt.contains("SAQ questions have no `choices`"))
    }

    func testPromptCanRequestMultipleSelection() throws {
        let prompt = QuizPrompt.make(topic: "Even numbers", questionCount: 5,
                                     difficulty: .mixed, includeMultipleSelect: true, format: try bundledFormat())
        XCTAssertTrue(prompt.contains("Include select-all-that-apply questions"))
        XCTAssertTrue(prompt.contains("\"correctAnswerIds\": [\"a\", \"c\"]"))
    }

    func testBundledFormatMatchesDocumentedFormat() throws {
        let documented = try String(contentsOf: sourceURL("LEARPER_PROMPT_DOC_PATH", fallback: "docs/QUESTION_FORMAT.md"))
        let bundled = try bundledFormat()
        XCTAssertEqual(bundled, documented)
        let loaded = try XCTUnwrap(QuizPrompt.formatDocument)
        XCTAssertEqual(loaded, documented)
    }

    private func bundledFormat() throws -> String {
        if ProcessInfo.processInfo.environment["LEARPER_PROMPT_PATH"] != nil {
            return try String(contentsOf: sourceURL("LEARPER_PROMPT_PATH", fallback: ""))
        }
        return try XCTUnwrap(QuizPrompt.formatDocument)
    }

    private func sourceURL(_ variable: String, fallback: String) -> URL {
        let path = ProcessInfo.processInfo.environment[variable] ?? fallback
        return URL(fileURLWithPath: path)
    }
}
