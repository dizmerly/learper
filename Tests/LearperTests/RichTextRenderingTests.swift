import Foundation
#if LEARPER_MANUAL_TEST_RUNNER
import LearperTestSupport
#else
import XCTest
#endif
@testable import Learper

final class RichTextRenderingTests: XCTestCase {
    func testPlainAnswersAvoidWebKit() {
        for text in ["", "42", "A directed graph", "3.14", "O(n)", "α → β", "Which value is correct?"] {
            XCTAssertFalse(RichTextRendering.needsWebView(text), text)
        }
    }

    func testFormattedContentKeepsFullRenderer() {
        for text in [
            "$x^2$", "$$x$$", "`value`", "```python\nprint(42)\n```",
            "```graph\na > b\n```", "**bold**", "_italic_", "[link](https://example.com)",
            "# Heading", "1. item", "2) item", "- item", "a\nb", "&amp;", "\\*escaped*",
            "    indented code", "\tindented code"
        ] {
            XCTAssertTrue(RichTextRendering.needsWebView(text), text)
        }
    }

    func testSampleWebViewReduction() throws {
        let set = try TestFixtures.sampleSet()
        let fields = set.questions.flatMap { question in
            [question.question, question.description ?? "", question.explanation]
                + question.hints + question.choices.map(\.text)
        }.filter { !$0.isEmpty }
        let webCount = fields.filter(RichTextRendering.needsWebView).count
        XCTAssertTrue(webCount < fields.count)
        print("Sample rich-text fields requiring WebKit: \(webCount)/\(fields.count) (previously all \(fields.count))")
    }
}
