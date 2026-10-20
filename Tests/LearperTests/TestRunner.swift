#if LEARPER_MANUAL_TEST_RUNNER
import LearperTestSupport

@main
enum TestRunner {
    @MainActor
    static func main() {
        XCTMain([
            testCase([
                ("testPlainAnswersAvoidWebKit", RichTextRenderingTests.testPlainAnswersAvoidWebKit),
                ("testFormattedContentKeepsFullRenderer", RichTextRenderingTests.testFormattedContentKeepsFullRenderer),
                ("testSampleWebViewReduction", RichTextRenderingTests.testSampleWebViewReduction)
            ]),
            testCase([
                ("testGeneratedPromptIncludesCompleteFormatAndUserOptions", QuizPromptTests.testGeneratedPromptIncludesCompleteFormatAndUserOptions),
                ("testShortAnswerPromptSelectsSAQFormat", QuizPromptTests.testShortAnswerPromptSelectsSAQFormat),
                ("testPromptCanRequestMultipleSelection", QuizPromptTests.testPromptCanRequestMultipleSelection),
                ("testBundledFormatMatchesDocumentedFormat", QuizPromptTests.testBundledFormatMatchesDocumentedFormat)
            ]),
            testCase([
                ("testSampleDecodesAndRoundTripsRichContent", QuizModelsTests.testSampleDecodesAndRoundTripsRichContent),
                ("testRejectsUnsupportedVersionAndEmptySetFields", QuizModelsTests.testRejectsUnsupportedVersionAndEmptySetFields),
                ("testRejectsDuplicateQuestionIDsAndMissingQuestionText", QuizModelsTests.testRejectsDuplicateQuestionIDsAndMissingQuestionText),
                ("testRejectsChoiceCountDuplicateIDsAndBadAnswer", QuizModelsTests.testRejectsChoiceCountDuplicateIDsAndBadAnswer),
                ("testRejectsMalformedJSONAndMissingRequiredHints", QuizModelsTests.testRejectsMalformedJSONAndMissingRequiredHints),
                ("testAcceptsReservedImageMetadataWithoutRequiringIt", QuizModelsTests.testAcceptsReservedImageMetadataWithoutRequiringIt),
                ("testShortAnswerDecodesWithoutChoicesAndKeepsLegacyMCQ", QuizModelsTests.testShortAnswerDecodesWithoutChoicesAndKeepsLegacyMCQ),
                ("testWeightValidationAndRoundTrip", QuizModelsTests.testWeightValidationAndRoundTrip),
                ("testMultipleSelectionValidationAndRoundTrip", QuizModelsTests.testMultipleSelectionValidationAndRoundTrip)
            ]),
            testCase([
                ("testCannotSubmitOrAdvanceWithoutAnswer", QuizSessionTests.testCannotSubmitOrAdvanceWithoutAnswer),
                ("testHintsStopAtAvailableCountAndResetOnNextQuestion", QuizSessionTests.testHintsStopAtAvailableCountAndResetOnNextQuestion),
                ("testWrongAnswerLocksSelectionAndCountsCorrectly", QuizSessionTests.testWrongAnswerLocksSelectionAndCountsCorrectly),
                ("testCompletionAndRetry", QuizSessionTests.testCompletionAndRetry),
                ("testNumberKeysAndSpaceActionFollowQuizState", QuizSessionTests.testNumberKeysAndSpaceActionFollowQuizState),
                ("testStatisticsIdentifyMissedQuestionAndSelectedAnswer", QuizSessionTests.testStatisticsIdentifyMissedQuestionAndSelectedAnswer),
                ("testShortAnswerCompletionAndGradingPrompt", QuizSessionTests.testShortAnswerCompletionAndGradingPrompt),
                ("testRenamingQuizKeepsSessionAnswers", QuizSessionTests.testRenamingQuizKeepsSessionAnswers),
                ("testRatingsChangeWeightAndGateAdvancement", QuizSessionTests.testRatingsChangeWeightAndGateAdvancement),
                ("testFolderPracticeCoversUnknownCardsAndCopiesWeightedResults", QuizSessionTests.testFolderPracticeCoversUnknownCardsAndCopiesWeightedResults),
                ("testMultipleSelectionTogglesAndGradesExactSet", QuizSessionTests.testMultipleSelectionTogglesAndGradesExactSet),
                ("testUnknownAnswerAppearsInResultsAndCannotBeChanged", QuizSessionTests.testUnknownAnswerAppearsInResultsAndCannotBeChanged),
                ("testQuestionNavigationPreservesDraftsAndSubmittedAnswers", QuizSessionTests.testQuestionNavigationPreservesDraftsAndSubmittedAnswers),
                ("testQuestionDotsSlideWithinTenQuestionWindow", QuizSessionTests.testQuestionDotsSlideWithinTenQuestionWindow)
            ]),
            testCase([
                ("testImportPersistsAndReplacesMatchingID", QuizLibraryTests.testImportPersistsAndReplacesMatchingID),
                ("testInvalidImportDoesNotOverwriteSavedSet", QuizLibraryTests.testInvalidImportDoesNotOverwriteSavedSet),
                ("testRemovingSelectedSetUpdatesSelectionAndDisk", QuizLibraryTests.testRemovingSelectedSetUpdatesSelectionAndDisk),
                ("testCorruptLibraryReportsLoadError", QuizLibraryTests.testCorruptLibraryReportsLoadError),
                ("testRemovingLastSetLeavesAnEmptySavedLibrary", QuizLibraryTests.testRemovingLastSetLeavesAnEmptySavedLibrary),
                ("testSaveFailureDoesNotChangeInMemoryLibrary", QuizLibraryTests.testSaveFailureDoesNotChangeInMemoryLibrary),
                ("testImportsStandaloneChatbotJSONFile", QuizLibraryTests.testImportsStandaloneChatbotJSONFile),
                ("testRenameAndDeleteSpecificQuizPersistWithoutChangingOtherSelection", QuizLibraryTests.testRenameAndDeleteSpecificQuizPersistWithoutChangingOtherSelection),
                ("testLegacyLibraryMigratesFoldersAndWeightsPersist", QuizLibraryTests.testLegacyLibraryMigratesFoldersAndWeightsPersist),
                ("testDroppedQuizMovesBetweenFoldersAndUngrouped", QuizLibraryTests.testDroppedQuizMovesBetweenFoldersAndUngrouped)
            ])
        ])
    }
}
#endif
