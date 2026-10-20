import AppKit
import JavaScriptCore
import WebKit

func fail(_ message: String) -> Never {
    fputs("Graph test failed: \(message)\n", stderr)
    exit(1)
}

guard CommandLine.arguments.count == 2 else { fail("Pass the project root") }
let projectRoot = URL(fileURLWithPath: CommandLine.arguments[1])
let webRoot = projectRoot.appendingPathComponent("Sources/Learper/Resources/Web")
let context = JSContext()!
context.exceptionHandler = { _, exception in fail(exception?.toString() ?? "JavaScript exception") }
context.evaluateScript("var window = this;")
context.evaluateScript(try String(contentsOf: webRoot.appendingPathComponent("graph.js"), encoding: .utf8))
context.setObject(
    try String(contentsOf: projectRoot.appendingPathComponent("Sources/Learper/Resources/graph-theory-quiz.json"), encoding: .utf8),
    forKeyedSubscript: "graphQuizSource" as NSString
)
context.evaluateScript(try String(contentsOf: projectRoot.appendingPathComponent("scripts/graph_test.js"), encoding: .utf8))
print("\(context.objectForKeyedSubscript("graphTestCount")!.toInt32()) graph parser/layout/safety checks passed")

final class WebCheck: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    let webView: WKWebView
    let window: NSWindow
    var stage = 0
    var actions: [String: String] = [:]

    override init() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 840, height: 720), configuration: configuration)
        window = NSWindow(contentRect: webView.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        super.init()
        configuration.userContentController.add(self, name: "graphAction")
        webView.navigationDelegate = self
        window.contentView = webView
    }

    func start() {
        webView.loadFileURL(webRoot.appendingPathComponent("index.html"), allowingReadAccessTo: webRoot)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: String], let action = body["action"], let text = body["text"] else { fail("Malformed editor bridge message") }
        actions[action] = text
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { fail(error.localizedDescription) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { fail(error.localizedDescription) }

    func check(_ script: String, then completion: @escaping () -> Void) {
        webView.evaluateJavaScript(script) { value, error in
            if let error { fail(error.localizedDescription) }
            guard value as? Bool == true else { fail("WebKit assertion: \(script)") }
            completion()
        }
    }

    func snapshot(_ name: String, then completion: @escaping () -> Void) {
        // Give layout and paint time to settle before checking the actual image.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.webView.takeSnapshot(with: nil) { image, error in
                guard error == nil, let tiff = image?.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiff),
                      let data = bitmap.representation(using: .png, properties: [:]) else { fail("Could not capture WebKit preview") }
                do { try data.write(to: projectRoot.appendingPathComponent(".build/tests/\(name).png")) }
                catch { fail(error.localizedDescription) }
                completion()
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if stage == 0 {
            let fixture = "# Directed paths\n```graph\na>b>c\nb>d>e\n```\nMermaid:\n```mermaid\nflowchart LR\n  A --> B\n```\nInline math: $x^2$.\n```python\nprint(42)\n```\n```graph\na >\n```\n```mermaid\ninvalid diagram\n```"
            let encoded = String(data: try! JSONEncoder().encode(fixture), encoding: .utf8)!
            check("""
                (() => {
                  render(\(encoded), 16);
                  const diagrams = document.querySelectorAll('.graph-diagram svg');
                  const ids = [...document.querySelectorAll('marker')].map(marker => marker.id);
                  return diagrams.length === 1 && diagrams[0].querySelectorAll('.vertex').length === 5 &&
                    diagrams[0].querySelectorAll('.edge').length === 4 && new Set(ids).size === ids.length &&
                    document.querySelectorAll('.graph-error').length === 1 &&
                    document.querySelectorAll('.katex').length > 0 && document.querySelectorAll('.hljs-number').length > 0;
                })()
                """) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                  self.check("document.querySelector('.mermaid-diagram svg') !== null && document.querySelector('.mermaid-error') !== null && !document.querySelector('[id^=dlearper-rich]')") {
                    self.snapshot("graph-richtext") {
                    self.check("""
                        (() => {
                          const source = 'Inline math: $x^2$.\\n'.repeat(40);
                          render(source, 16);
                          const tall = contentHeight();
                          const firstNode = document.getElementById('content').firstChild;
                          for (let i = 0; i < 100; i++) render(source, 16);
                          const reused = firstNode === document.getElementById('content').firstChild;
                          render(source, 18);
                          const resizedWithoutParsing = firstNode === document.getElementById('content').firstChild;
                          render('Short $x$.', 16);
                          return reused && resizedWithoutParsing && contentHeight() < tall && contentHeight() < 100;
                        })()
                        """) {
                        print("Repeated renders reuse DOM; content height shrinks after long questions")
                        self.stage = 1
                        webView.loadFileURL(webRoot.appendingPathComponent("graph-editor.html"), allowingReadAccessTo: webRoot)
                    }
                    }
                  }
                }
            }
        } else {
            webView.evaluateJavaScript("setGraphSource('flowchart LR\\n  A --> B')") { _, error in
                if let error { fail(error.localizedDescription) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.check("document.querySelector('#preview svg') !== null && !exportButton.disabled") {
                        self.check("copyButton.click(); exportButton.click(); setGraphSource('invalid diagram'); true") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.check("exportButton.disabled && copyButton.disabled && !error.hidden && !document.querySelector('[id^=dlearper-editor]')") {
                                    self.check("document.querySelector('[data-example=flowchart]').click(); true") {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            self.check("document.querySelector('#preview svg') !== null && !exportButton.disabled") {
                                                self.snapshot("graph-editor") {
                                                    guard self.actions["copy"] == "```mermaid\nflowchart LR\n  A --> B\n```",
                                                          self.actions["export"]?.hasPrefix("<svg") == true,
                                                          self.actions["draft"]?.contains("flowchart LR") == true else { fail("Mermaid copy, export, or draft bridge did not match editor content") }
                                                    print("WebKit Mermaid rendering, rich text, live editor, copy/export, and draft checks passed")
                                                    exit(0)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

let application = NSApplication.shared
application.setActivationPolicy(.prohibited)
let webCheck = WebCheck()
webCheck.start()
DispatchQueue.main.asyncAfter(deadline: .now() + 60) { fail("WebKit checks timed out") }
application.run()
