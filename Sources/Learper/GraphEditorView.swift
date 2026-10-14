import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct GraphEditorView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Create Graph").font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(20)
            Divider()
            GraphEditorWebView()
        }
        .frame(width: 840, height: 620)
    }
}

private struct GraphEditorWebView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "graphAction")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.underPageBackgroundColor = .clear
        webView.setValue(false, forKey: "drawsBackground")
        if let url = QuizResources.bundle.url(forResource: "graph-editor", withExtension: "html", subdirectory: "Web") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) { }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "graphAction")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        private let draftKey = "Learper.graphDraft"

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let draft = UserDefaults.standard.string(forKey: draftKey),
                  let data = try? JSONEncoder().encode(draft),
                  let encoded = String(data: data, encoding: .utf8) else { return }
            webView.evaluateJavaScript("setGraphSource(\(encoded));", completionHandler: nil)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(navigationAction.navigationType == .linkActivated ? .cancel : .allow)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: String],
                  let action = body["action"], let text = body["text"] else { return }
            switch action {
            case "draft":
                guard text.count <= 12_000 else { return }
                UserDefaults.standard.set(text, forKey: draftKey)
            case "copy":
                guard text.count <= 12_100 else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            case "export":
                guard text.utf8.count <= 1_000_000, text.hasPrefix("<svg"),
                      let window = message.webView?.window else { return }
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.svg]
                panel.nameFieldStringValue = "learper-graph.svg"
                panel.beginSheetModal(for: window) { response in
                    guard response == .OK, let url = panel.url else { return }
                    do { try text.write(to: url, atomically: true, encoding: .utf8) }
                    catch {
                        let alert = NSAlert(error: error)
                        alert.beginSheetModal(for: window)
                    }
                }
            default: break
            }
        }
    }
}
