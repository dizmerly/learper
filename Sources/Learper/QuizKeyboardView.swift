import AppKit
import SwiftUI

enum QuizKey {
    case choice(Int)
    case primaryAction
}

/// Routes quiz shortcuts only to the Learper window that owns this view.
struct QuizKeyboardView: NSViewRepresentable {
    let onKey: (QuizKey) -> Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.view = view
        context.coordinator.installMonitor()
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        context.coordinator.onKey = onKey
    }

    static func dismantleNSView(_ view: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class Coordinator {
        weak var view: NSView?
        var onKey: (QuizKey) -> Bool = { _ in false }
        private var monitor: Any?

        func installMonitor() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self,
                      let window = self.view?.window,
                      event.window === window,
                      NSApp.keyWindow === window,
                      !event.isARepeat,
                      event.modifierFlags.intersection([.command, .control, .option]).isEmpty
                else { return event }

                let handled: Bool
                switch event.charactersIgnoringModifiers {
                case "1": handled = self.onKey(.choice(1))
                case "2": handled = self.onKey(.choice(2))
                case "3": handled = self.onKey(.choice(3))
                case "4": handled = self.onKey(.choice(4))
                case " ": handled = self.onKey(.primaryAction)
                default: return event
                }
                return handled ? nil : event
            }
        }

        func removeMonitor() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
    }
}
