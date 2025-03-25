//
//  SSOWebView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//


import SwiftUI
import WebKit

struct SSOWebView: View {
    let url: URL
    @Binding var isPresented: Bool
    var onSuccessfulLogin: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                WebViewRepresentable(url: url, onNavigationChange: { url in
                    if url.absoluteString.starts(with: "ai4edu://callback") {
                        if APIService.shared.handleSSOCallback(url: url) {
                            isPresented = false
                            onSuccessfulLogin()
                        }
                    }
                })
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .padding()
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    let onNavigationChange: (URL) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable
        
        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if url.absoluteString.starts(with: "ai4edu://callback") {
                    parent.onNavigationChange(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}