import SwiftUI

@main
struct LearperApp: App {
    @StateObject private var library = QuizLibrary()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .preferredColorScheme(.dark)
                .frame(minWidth: 880, minHeight: 660)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Quiz JSON…") { library.importFile() }
                    .keyboardShortcut("o", modifiers: .command)
                Button("Paste Quiz JSON") { library.importClipboard() }
                    .keyboardShortcut("v", modifiers: [.command, .shift])
            }
        }
    }
}
