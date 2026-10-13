import Foundation
#if LEARPER_MANUAL_TEST_RUNNER
import LearperTestSupport
#else
import XCTest
#endif
@testable import Learper

@MainActor
final class QuizLibraryTests: XCTestCase {
    func testImportPersistsAndReplacesMatchingID() throws {
        let url = TestFixtures.temporaryLibraryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let library = try emptyLibrary(at: url)
        let original = TestFixtures.set(title: "First title")
        let replacement = TestFixtures.set(title: "Updated title")

        try library.importData(QuizCodec.encode(original))
        XCTAssertEqual(library.selectedSetID, original.id)
        try library.importData(QuizCodec.encode(replacement))
        XCTAssertEqual(library.sets, [replacement])

        let reopened = QuizLibrary(storageURL: url)
        XCTAssertEqual(reopened.sets, [replacement])
        XCTAssertEqual(reopened.selectedSetID, replacement.id)
    }

    func testInvalidImportDoesNotOverwriteSavedSet() throws {
        let url = TestFixtures.temporaryLibraryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let library = try emptyLibrary(at: url)
        let valid = TestFixtures.set()
        try library.importData(QuizCodec.encode(valid))

        let invalid = TestFixtures.set(questions: [TestFixtures.question(answer: "missing")])
        XCTAssertThrowsError(try library.importData(QuizCodec.encode(invalid)))
        XCTAssertEqual(library.sets, [valid])
        XCTAssertEqual(QuizLibrary(storageURL: url).sets, [valid])
    }

    func testRemovingSelectedSetUpdatesSelectionAndDisk() throws {
        let url = TestFixtures.temporaryLibraryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let library = try emptyLibrary(at: url)
        let first = TestFixtures.set(id: "first")
        let second = TestFixtures.set(id: "second")
        try library.importData(QuizCodec.encode(first))
        try library.importData(QuizCodec.encode(second))

        library.removeSelectedSet()
        XCTAssertEqual(library.sets, [first])
        XCTAssertEqual(library.selectedSetID, first.id)
        XCTAssertEqual(QuizLibrary(storageURL: url).sets, [first])
    }

    func testCorruptLibraryReportsLoadError() throws {
        let url = TestFixtures.temporaryLibraryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("broken JSON".utf8).write(to: url)

        let library = QuizLibrary(storageURL: url)
        XCTAssertTrue(library.sets.isEmpty)
        XCTAssertNotNil(library.errorMessage)
    }

    func testRemovingLastSetLeavesAnEmptySavedLibrary() throws {
        let url = TestFixtures.temporaryLibraryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let library = try emptyLibrary(at: url)
        try library.importData(QuizCodec.encode(TestFixtures.set()))

        library.removeSelectedSet()
        XCTAssertTrue(library.sets.isEmpty)
        XCTAssertNil(library.selectedSetID)
        XCTAssertTrue(QuizLibrary(storageURL: url).sets.isEmpty)
        library.removeSelectedSet()
        XCTAssertNil(library.errorMessage)
    }

    func testSaveFailureDoesNotChangeInMemoryLibrary() throws {
        let parentFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("LearperTests-blocked-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: parentFile) }
        try Data("not a directory".utf8).write(to: parentFile)
        let library = QuizLibrary(storageURL: parentFile.appendingPathComponent("library.json"))

        XCTAssertThrowsError(try library.importData(QuizCodec.encode(TestFixtures.set())))
        XCTAssertTrue(library.sets.isEmpty)
        XCTAssertNil(library.selectedSetID)
    }

    func testImportsStandaloneChatbotJSONFile() throws {
        let url = TestFixtures.temporaryLibraryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let library = try emptyLibrary(at: url)
        let downloadedFile = url.deletingLastPathComponent().appendingPathComponent("learper-quiz.json")
        let json = #"{"version":1,"id":"bot-quiz","title":"Bot quiz","questions":[{"id":"q1","question":"What is 2 + 2?","hints":[],"choices":[{"id":"a","text":"3"},{"id":"b","text":"4"}],"correctAnswerId":"b","explanation":"Adding two and two gives four."}]}"#
        try Data(json.utf8).write(to: downloadedFile)

        try library.importURL(downloadedFile)
        XCTAssertEqual(library.selectedSet?.title, "Bot quiz")
        XCTAssertEqual(library.selectedSet?.questions[0].correctChoice?.text, "4")
        XCTAssertNil(library.selectedSet?.questions[0].image)
        XCTAssertNil(library.selectedSet?.questions[0].description)
    }

    private func emptyLibrary(at url: URL) throws -> QuizLibrary {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("[]".utf8).write(to: url)
        return QuizLibrary(storageURL: url)
    }
}
