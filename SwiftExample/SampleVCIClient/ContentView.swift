

import SwiftUI
import WebKit

enum FlowType {
    case credentialOffer
    case trustedIssuer
}

struct AuthSheetItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ContentView: View {
    @State private var resultText: String = ""
    @State private var isLoading: Bool = false
    @State private var showScanner: Bool = false
    @State private var flowType: FlowType?
    @State private var authSheetItem: AuthSheetItem? = nil

    var body: some View {
        VStack(spacing: 24) {
            Text("🔐 VCIClient Demo")
                .font(.title2)
                .bold()

            VStack(spacing: 16) {
                Button("Start Credential Offer Flow") {
                    flowType = .credentialOffer
                    showScanner = true
                }
                .buttonStyle(FilledButtonStyle(color: .blue))

                Button("Start Trusted Issuer Flow") {
                    flowType = .trustedIssuer
                    isLoading = true
                    resultText = ""
                    VCIClientWrapper.shared.startTrustedIssuerFlow(from: "") { result in
                        DispatchQueue.main.async {
                            isLoading = false
                            resultText = result
                            authSheetItem = nil
                        }
                    }
                }
                .buttonStyle(FilledButtonStyle(color: .green))
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowAuthWebView"))) { notification in
                if let urlStr = notification.object as? String, let url = URL(string: urlStr) {
                    authSheetItem = AuthSheetItem(url: url)
                }
            }
            .sheet(item: $authSheetItem) { item in
                AuthWebView(authURL: item.url)
            }

            if isLoading { ProgressView() }

            if !resultText.isEmpty {
                ScrollView {
                    Text(resultText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .frame(height: 300)
            }
        }
        .padding()
        .fullScreenCover(isPresented: $showScanner) {
            QRScannerView(
                onFound: handleScannedCode,
                onCancel: { showScanner = false }
            )
        }
    }

    private func handleScannedCode(_ code: String) {
        showScanner = false
        isLoading = true
        resultText = ""

        VCIClientWrapper.shared.startCredentialOfferFlow(from: code) { result in
            isLoading = false
            resultText = result
            authSheetItem = nil
        }
    }
}

struct FilledButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

struct AuthWebView: UIViewRepresentable {
    let authURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: authURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.absoluteString.starts(with: "io.mosip.residentapp.inji://oauthredirect"),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                NotificationCenter.default.post(name: Notification.Name("AuthCodeReceived"), object: code)

                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
