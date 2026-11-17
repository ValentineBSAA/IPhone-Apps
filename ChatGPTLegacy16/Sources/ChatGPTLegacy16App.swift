import SwiftUI
import WebKit
import SafariServices

@main
struct ChatGPTLegacy16App: App {
    var body: some Scene {
        WindowGroup {
            ChatScreen()
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
final class BrowserModel: ObservableObject {
    @Published var loading = false
    @Published var canGoBack = false
    @Published var errorMessage: String?
    @Published var openSafari = false

    let webView: WKWebView
    static let home = URL(string: "https://chatgpt.com/")!

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isInspectable = false
    }

    func homePage() { webView.load(URLRequest(url: Self.home)) }
    func reload() { webView.reload() }
    func goBack() { if webView.canGoBack { webView.goBack() } }
}

struct ChatScreen: View {
    @StateObject private var browser = BrowserModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(.mint)
                Text("Chat Companion")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if browser.loading {
                    ProgressView().tint(.mint).scaleEffect(0.8)
                }
                Button(action: browser.goBack) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!browser.canGoBack)
                .accessibilityLabel("Back")
                Button(action: browser.reload) {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh")
                Button(action: { browser.openSafari = true }) {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("Open ChatGPT in Safari")
            }
            .font(.system(size: 17))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color(red: 0.08, green: 0.09, blue: 0.10))

            ChatWebView(browser: browser)
                .background(Color(red: 0.08, green: 0.09, blue: 0.10))
        }
        .background(Color(red: 0.08, green: 0.09, blue: 0.10))
        .alert("Page couldn't load", isPresented: Binding(
            get: { browser.errorMessage != nil },
            set: { if !$0 { browser.errorMessage = nil } }
        )) {
            Button("Retry") { browser.homePage(); browser.errorMessage = nil }
            Button("Open Safari") { browser.openSafari = true; browser.errorMessage = nil }
            Button("Cancel", role: .cancel) { browser.errorMessage = nil }
        } message: {
            Text(browser.errorMessage ?? "Check the internet connection.")
        }
        .sheet(isPresented: $browser.openSafari) {
            SafariPage(url: BrowserModel.home)
                .ignoresSafeArea()
        }
    }
}

struct ChatWebView: UIViewRepresentable {
    @ObservedObject var browser: BrowserModel

    func makeCoordinator() -> Coordinator { Coordinator(browser: browser) }

    func makeUIView(context: Context) -> WKWebView {
        let view = browser.webView
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        if view.url == nil { browser.homePage() }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let browser: BrowserModel
        init(browser: BrowserModel) { self.browser = browser }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            browser.loading = true
            browser.errorMessage = nil
            browser.canGoBack = webView.canGoBack
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            browser.loading = false
            browser.canGoBack = webView.canGoBack
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }
        private func handle(_ error: Error) {
            browser.loading = false
            if (error as NSError).code != NSURLErrorCancelled {
                browser.errorMessage = error.localizedDescription
            }
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            // Block non-web URL schemes from being loaded as web content.
            guard let scheme = url.scheme?.lowercased(), ["http", "https", "about", "blob"].contains(scheme) else {
                decisionHandler(.cancel)
                return
            }
            // Keep auth/navigation inside ChatGPT's context; unrelated external links open in Safari.
            let host = (url.host ?? "").lowercased()
            let allowed = host == "chatgpt.com" || host.hasSuffix(".chatgpt.com") ||
                host == "openai.com" || host.hasSuffix(".openai.com") ||
                host == "auth0.openai.com" || host == "appleid.apple.com"
            if !allowed && navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                if url.scheme == "https" || url.scheme == "http" {
                    webView.load(URLRequest(url: url))
                }
            }
            return nil
        }
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.prompt)
        }
    }
}

struct SafariPage: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
