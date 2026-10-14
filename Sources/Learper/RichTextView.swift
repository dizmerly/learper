import AppKit
import SwiftUI
import WebKit

/// A small, non-scrolling WebKit surface for Markdown, KaTeX, and code highlighting.
struct RichTextView: NSViewRepresentable {
    let markdown: String
    var textSize: CGFloat = 16
    @ViewState private var height: CGFloat = 28

    func makeCoordinator() -> Coordinator { Coordinator(height: $height) }

    func makeNSView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "height")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.underPageBackgroundColor = .clear
        webView.setValue(false, forKey: "drawsBackground")

        if let url = QuizResources.bundle.url(
            forResource: "index", withExtension: "html", subdirectory: "Web"
        ) {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.height = $height
        let signature = "\(textSize)|\(markdown)"
        guard context.coordinator.lastSignature != signature else { return }
        context.coordinator.lastSignature = signature
        context.coordinator.markdown = markdown
        context.coordinator.textSize = textSize
        context.coordinator.render(in: webView)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "height")
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: WKWebView,
        context: Context
    ) -> CGSize? {
        CGSize(width: proposal.width ?? 300, height: height)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var height: Binding<CGFloat>
        var markdown = ""
        var textSize: CGFloat = 16
        var lastSignature = ""
        private var isReady = false

        init(height: Binding<CGFloat>) { self.height = height }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isReady = true
            render(in: webView)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(navigationAction.navigationType == .linkActivated ? .cancel : .allow)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let value = message.body as? NSNumber else { return }
            let measured = max(24, CGFloat(value.doubleValue))
            if abs(height.wrappedValue - measured) > 1 { height.wrappedValue = measured }
        }

        func render(in webView: WKWebView) {
            guard isReady,
                  let data = try? JSONEncoder().encode(markdown),
                  let encoded = String(data: data, encoding: .utf8) else { return }
            webView.evaluateJavaScript("render(\(encoded), \(textSize));", completionHandler: nil)
        }
    }
}
