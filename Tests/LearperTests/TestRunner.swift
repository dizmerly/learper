#if LEARPER_MANUAL_TEST_RUNNER
import LearperTestSupport

@main
enum TestRunner {
    @MainActor
    static func main() {
        XCTMain([
            testCase([
                ("testSampleDecodesAndRoundTripsRichContent", QuizModelsTests.testSampleDecodesAndRoundTripsRichContent),
                ("testRejectsUnsupportedVersionAndEmptySetFields", QuizModelsTests.testRejectsUnsupportedVersionAndEmptySetFields),
                ("testRejectsDuplicateQuestionIDsAndMissingQuestionText", QuizModelsTests.testRejectsDuplicateQuestionIDsAndMissingQuestionText),
                ("testRejectsChoiceCountDuplicateIDsAndBadAnswer", QuizModelsTests.testRejectsChoiceCountDuplicateIDsAndBadAnswer),
                ("testRejectsMalformedJSONAndMissingRequiredHints", QuizModelsTests.testRejectsMalformedJSONAndMissingRequiredHints),
                ("testAcceptsReservedImageMetadataWithoutRequiringIt", QuizModelsTests.testAcceptsReservedImageMetadataWithoutRequiringIt)
            ]),
            testCase([
                ("testCannotSubmitOrAdvanceWithoutAnswer", QuizSessionTests.testCannotSubmitOrAdvanceWithoutAnswer),
                ("testHintsStopAtAvailableCountAndResetOnNextQuestion", QuizSessionTests.testHintsStopAtAvailableCountAndResetOnNextQuestion),
                ("testWrongAnswerLocksSelectionAndCountsCorrectly", QuizSessionTests.testWrongAnswerLocksSelectionAndCountsCorrectly),
                ("testCompletionAndRetry", QuizSessionTests.testCompletionAndRetry)
            ]),
            testCase([
                ("testImportPersistsAndReplacesMatchingID", QuizLibraryTests.testImportPersistsAndReplacesMatchingID),
                ("testInvalidImportDoesNotOverwriteSavedSet", QuizLibraryTests.testInvalidImportDoesNotOverwriteSavedSet),
                ("testRemovingSelectedSetUpdatesSelectionAndDisk", QuizLibraryTests.testRemovingSelectedSetUpdatesSelectionAndDisk),
                ("testCorruptLibraryReportsLoadError", QuizLibraryTests.testCorruptLibraryReportsLoadError),
                ("testRemovingLastSetLeavesAnEmptySavedLibrary", QuizLibraryTests.testRemovingLastSetLeavesAnEmptySavedLibrary),
                ("testSaveFailureDoesNotChangeInMemoryLibrary", QuizLibraryTests.testSaveFailureDoesNotChangeInMemoryLibrary),
                ("testImportsStandaloneChatbotJSONFile", QuizLibraryTests.testImportsStandaloneChatbotJSONFile)
            ])
        ])
    }
}
#endif
