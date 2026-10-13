import Foundation
import XCTest
@testable import Learper

final class QuizModelsTests: XCTestCase {
    func testBundledSampleDecodesAndValidates() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "sample-quiz", withExtension: "json"))
        let set = try QuizCodec.decode(Data(contentsOf: url))
        XCTAssertEqual(set.questions.count, 3)
        XCTAssertEqual(set.questions[0].correctChoice?.id, "b")
    }

    func testRejectsWrongAnswerID() throws {
        let data = Data(#"{"version":1,"id":"set","title":"Title","questions":[{"id":"q","question":"Q?","description":null,"hints":[],"choices":[{"id":"a","text":"A"},{"id":"b","text":"B"}],"correctAnswerId":"x","explanation":"Because.","image":null}]}"#.utf8)
        XCTAssertThrowsError(try QuizCodec.decode(data))
    }
}
