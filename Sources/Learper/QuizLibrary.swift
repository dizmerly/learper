import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class QuizLibrary: ObservableObject {
    @Published private(set) var sets: [QuizSet] = []
    @Published var selectedSetID: String?
    @Published var errorMessage: String?

    private let storageURL: URL

    init(storageURL: URL? = nil) {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("Learper", isDirectory: true)
        self.storageURL = storageURL ?? support.appendingPathComponent("library.json")
        load()
    }

    var selectedSet: QuizSet? { sets.first { $0.id == selectedSetID } }

    func importFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try importData(Data(contentsOf: url))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string),
              let data = text.data(using: .utf8) else {
            errorMessage = "Copy a JSON quiz set, then choose Paste JSON."
            return
        }
        do {
            try importData(data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importData(_ data: Data) throws {
        let set = try QuizCodec.decode(data)
        var updated = sets
        if let index = updated.firstIndex(where: { $0.id == set.id }) {
            updated[index] = set
        } else {
            updated.insert(set, at: 0)
        }
        try save(updated)
        sets = updated
        selectedSetID = set.id
    }

    func removeSelectedSet() {
        guard let selectedSetID else { return }
        let updated = sets.filter { $0.id != selectedSetID }
        do {
            try save(updated)
            sets = updated
            self.selectedSetID = updated.first?.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func load() {
        do {
            if FileManager.default.fileExists(atPath: storageURL.path) {
                let saved = try JSONDecoder().decode([QuizSet].self, from: Data(contentsOf: storageURL))
                for set in saved { try set.validate() }
                sets = saved
            } else if let sampleURL = QuizResources.bundle.url(forResource: "sample-quiz", withExtension: "json") {
                sets = [try QuizCodec.decode(Data(contentsOf: sampleURL))]
            }
            selectedSetID = sets.first?.id
        } catch {
            errorMessage = "Could not load the quiz library: \(error.localizedDescription)"
        }
    }

    private func save(_ updated: [QuizSet]) throws {
        try FileManager.default.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(updated).write(to: storageURL, options: .atomic)
    }
}
