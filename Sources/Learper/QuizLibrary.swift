import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class QuizLibrary: ObservableObject {
    @Published private(set) var sets: [QuizSet] = []
    @Published private(set) var groups: [QuizGroup] = []
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
    func sets(in groupID: String?) -> [QuizSet] { sets.filter { $0.groupID == groupID } }

    func importFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try importURL(url)
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
        var set = try QuizCodec.decode(data)
        var updated = sets
        if let index = updated.firstIndex(where: { $0.id == set.id }) {
            if set.groupID == nil { set.groupID = updated[index].groupID }
            updated[index] = set
        } else {
            updated.insert(set, at: 0)
        }
        if let groupID = set.groupID, !groups.contains(where: { $0.id == groupID }),
           let index = updated.firstIndex(where: { $0.id == set.id }) {
            updated[index].groupID = nil
        }
        try save(updated)
        sets = updated
        selectedSetID = set.id
    }

    func importURL(_ url: URL) throws {
        try importData(Data(contentsOf: url))
    }

    func removeSelectedSet() {
        guard let selectedSetID else { return }
        removeSet(id: selectedSetID)
    }

    func removeSet(id: String) {
        guard sets.contains(where: { $0.id == id }) else { return }
        let updated = sets.filter { $0.id != id }
        do {
            try save(updated)
            sets = updated
            if selectedSetID == id { selectedSetID = updated.first?.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameSet(id: String, to title: String) {
        let title = title.trimmed
        guard !title.isEmpty else {
            errorMessage = "Enter a quiz name."
            return
        }
        guard let index = sets.firstIndex(where: { $0.id == id }) else { return }
        var updated = sets
        updated[index].title = title
        do {
            try save(updated)
            sets = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createGroup(named name: String) {
        let name = name.trimmed
        guard !name.isEmpty else { errorMessage = "Enter a folder name."; return }
        let updated = groups + [QuizGroup(id: UUID().uuidString, name: name)]
        do { try save(sets, groups: updated); groups = updated }
        catch { errorMessage = error.localizedDescription }
    }

    func renameGroup(id: String, to name: String) {
        let name = name.trimmed
        guard !name.isEmpty else { errorMessage = "Enter a folder name."; return }
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        var updated = groups
        updated[index].name = name
        do { try save(sets, groups: updated); groups = updated }
        catch { errorMessage = error.localizedDescription }
    }

    func removeGroup(id: String) {
        guard groups.contains(where: { $0.id == id }) else { return }
        var updatedSets = sets
        for index in updatedSets.indices where updatedSets[index].groupID == id {
            updatedSets[index].groupID = nil
        }
        let updatedGroups = groups.filter { $0.id != id }
        do {
            try save(updatedSets, groups: updatedGroups)
            sets = updatedSets
            groups = updatedGroups
        } catch { errorMessage = error.localizedDescription }
    }

    func moveSet(id: String, to groupID: String?) {
        guard groupID == nil || groups.contains(where: { $0.id == groupID }),
              let index = sets.firstIndex(where: { $0.id == id }) else { return }
        var updated = sets
        updated[index].groupID = groupID
        do { try save(updated); sets = updated }
        catch { errorMessage = error.localizedDescription }
    }

    @discardableResult
    func moveDroppedSet(_ value: String, to groupID: String?) -> Bool {
        let prefix = "learper-quiz:"
        guard value.hasPrefix(prefix) else { return false }
        let id = String(value.dropFirst(prefix.count))
        guard let set = sets.first(where: { $0.id == id }), set.groupID != groupID else { return false }
        moveSet(id: id, to: groupID)
        return sets.first(where: { $0.id == id })?.groupID == groupID
    }

    @discardableResult
    func rateQuestion(setID: String, questionID: String, rating: PracticeRating) -> Double? {
        guard let setIndex = sets.firstIndex(where: { $0.id == setID }),
              let questionIndex = sets[setIndex].questions.firstIndex(where: { $0.id == questionID }) else { return nil }
        var updated = sets
        let weight = rating.updatedWeight(from: updated[setIndex].questions[questionIndex].weight)
        updated[setIndex].questions[questionIndex].weight = weight
        do { try save(updated); sets = updated; return weight }
        catch { errorMessage = error.localizedDescription; return nil }
    }

    func exportSet(id: String) {
        guard let set = sets.first(where: { $0.id == id }) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(set.id)-updated.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try QuizCodec.encode(set).write(to: url, options: .atomic) }
        catch { errorMessage = error.localizedDescription }
    }

    private func load() {
        do {
            if FileManager.default.fileExists(atPath: storageURL.path) {
                let data = try Data(contentsOf: storageURL)
                if let saved = try? JSONDecoder().decode(StoredLibrary.self, from: data) {
                    for set in saved.sets { try set.validate() }
                    sets = saved.sets
                    groups = saved.groups
                } else {
                    let saved = try JSONDecoder().decode([QuizSet].self, from: data)
                    for set in saved { try set.validate() }
                    sets = saved
                }
            } else if let sampleURL = QuizResources.bundle.url(forResource: "sample-quiz", withExtension: "json") {
                sets = [try QuizCodec.decode(Data(contentsOf: sampleURL))]
            }
            selectedSetID = sets.first?.id
        } catch {
            errorMessage = "Could not load the quiz library: \(error.localizedDescription)"
        }
    }

    private struct StoredLibrary: Codable {
        let sets: [QuizSet]
        let groups: [QuizGroup]
    }

    private func save(_ updated: [QuizSet], groups updatedGroups: [QuizGroup]? = nil) throws {
        try FileManager.default.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(StoredLibrary(sets: updated, groups: updatedGroups ?? groups))
            .write(to: storageURL, options: .atomic)
    }
}
