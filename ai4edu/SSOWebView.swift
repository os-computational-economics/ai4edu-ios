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
    @State private var isLoading = true
    @State private var showLoadingIndicator = true
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
                // Header with close button
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
                
                // Loading indicator - only show after a short delay and when loading
                if showLoadingIndicator {
                    VStack {
                        ProgressView("Loading secure sign-in...")
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .transition(.opacity)
                }
                
                // Web view - always present but opacity controlled
                WebViewRepresentable(url: url, isLoading: $isLoading, onLoadingChanged: { isLoading in
                    // Use a delay to avoid showing/hiding the loader for brief loading changes
                    if isLoading {
                        // When loading starts, show indicator after a small delay
                        // to avoid flashing for very quick loads
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if self.isLoading { // Only show if still loading after delay
                                withAnimation(.easeIn(duration: 0.2)) {
                                    self.showLoadingIndicator = true
                                }
                            }
                        }
                    } else {
                        // When loading finishes, hide indicator with animation
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.showLoadingIndicator = false
                        }
                    }
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
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
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
            
            // Update parent loading state on main thread
            DispatchQueue.main.async {
                if self.parent.isLoading != isLoading {
                    self.parent.isLoading = isLoading
                    self.parent.onLoadingChanged(isLoading)
                }
            }
        }
    }
}