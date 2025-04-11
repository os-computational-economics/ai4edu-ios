//
//  SSOWebView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//


import SwiftUI
@preconcurrency import WebKit

struct SSOWebView: View {
    let url: URL
    @Binding var isPresented: Bool
    var onSuccessfulLogin: () -> Void
    var onCancel: (() -> Void)? = nil
    @State private var isLoading = true
    @State private var showLoadingIndicator = true
    @State private var opacity = 0.0
    @State private var loadingTimerWorkItem: DispatchWorkItem? = nil
    @State private var lastStateChange = Date()
    @State private var minimumLoadingTimeElapsed = false
    
    private let showDelay: TimeInterval = 0.6
    private let minimumLoadingTime: TimeInterval = 1.0
    private let debounceInterval: TimeInterval = 0.3
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
                HStack {
                    Text("Sign In")
                        .font(.headline)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                .background(Color(UIColor.systemBackground))
                
                if showLoadingIndicator {
                    VStack {
                        ProgressView("Loading secure sign-in...")
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .transition(.opacity)
                }
                
                WebViewRepresentable(url: url, isLoading: $isLoading, onLoadingChanged: { isLoading in
                    handleLoadingStateChange(isLoading)
                }, onNavigationChange: { url in
                    if url.absoluteString.starts(with: "ai4edu://callback") {
                        if APIService.shared.handleSSOCallback(url: url) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isPresented = false
                                onSuccessfulLogin()
                            }
                        }
                    }
                })
                .opacity(showLoadingIndicator ? 0 : 1)
            }
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()
            .frame(height: UIScreen.main.bounds.height * 0.75)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + minimumLoadingTime) {
                    minimumLoadingTimeElapsed = true
                    if !isLoading {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showLoadingIndicator = false
                        }
                    }
                }
            }
        }
    }
    
    private func handleLoadingStateChange(_ isNowLoading: Bool) {
        loadingTimerWorkItem?.cancel()
        
        let timeSinceLastChange = Date().timeIntervalSince(lastStateChange)
        lastStateChange = Date()
        
        let actualDelay = timeSinceLastChange < debounceInterval ? 
            debounceInterval : (isNowLoading ? showDelay : 0.1)
        
        let workItem = DispatchWorkItem {
            if isNowLoading {
                if self.isLoading {
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.showLoadingIndicator = true
                    }
                }
            } else {
                if minimumLoadingTimeElapsed {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.showLoadingIndicator = false
                    }
                }
            }
        }
        
        loadingTimerWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + actualDelay, execute: workItem)
    }
    
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
            onCancel?()
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    let onLoadingChanged: (Bool) -> Void
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
        private var pendingNavigations = Set<WKNavigation>()
        
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
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            pendingNavigations.insert(navigation)
            updateLoadingState()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            pendingNavigations.remove(navigation)
            updateLoadingState()
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            pendingNavigations.remove(navigation)
            updateLoadingState()
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            pendingNavigations.remove(navigation)
            updateLoadingState()
        }
        
        private func updateLoadingState() {
            let isLoading = !pendingNavigations.isEmpty
            
            DispatchQueue.main.async {
                if self.parent.isLoading != isLoading {
                    self.parent.isLoading = isLoading
                    self.parent.onLoadingChanged(isLoading)
                }
            }
        }
    }
}
