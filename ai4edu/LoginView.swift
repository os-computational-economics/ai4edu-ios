//
//  LoginView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//


import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var isLoggingIn = false
    @State private var showWebView = false
    @EnvironmentObject private var appState: AppState
    @State private var animateBackground = false
    @State private var cardOffset: CGFloat = 400
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.4),
                    Color.blue.opacity(0.3)
                ]),
                startPoint: animateBackground ? .topLeading : .bottomTrailing,
                endPoint: animateBackground ? .bottomTrailing : .topLeading
            )
            .edgesIgnoringSafeArea(.all)
            .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateBackground)
            .onAppear {
                animateBackground = true
            }
            
            // Content
            VStack {
                Spacer()
                
                // Logo and app name
                VStack(spacing: 20) {
                    Image("AI4EDULogo_White")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    VStack(spacing: 8) {
                        Text("AI4EDU")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("AI-Powered Learning")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .opacity(logoOpacity)
                }
                
                Spacer()
                
                // Login card
                VStack(spacing: 25) {
                    Text("Welcome")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Sign in to access your AI learning assistants and course materials")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                    
                    Button(action: {
                        // Add press animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            buttonScale = 0.95
                        }
                        
                        // Reset scale after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                buttonScale = 1.0
                            }
                            handleSSOLogin()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text("Sign in with CWRU Account")
                                .fontWeight(.semibold)
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .scaleEffect(buttonScale)
                    .disabled(isLoggingIn)
                    
                    if isLoggingIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                            .padding(.top, 5)
                    }
                    
                    // Terms and privacy
//                    VStack(spacing: 8) {
//                        Text("By signing in, you agree to our")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        
//                        HStack(spacing: 3) {
//                            Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
//                                .font(.caption)
//                                .foregroundColor(.blue)
//                            
//                            Text("and")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            
//                            Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
//                                .font(.caption)
//                                .foregroundColor(.blue)
//                        }
//                    }
//                    .padding(.top, 10)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 30)
                .offset(y: cardOffset)
                
                Spacer()
                
                // Footer
//                HStack(spacing: 4) {
//                    Text("Need help?")
//                        .font(.footnote)
//                        .foregroundColor(.white.opacity(0.8))
//                    
//                    Link("Contact Support", destination: URL(string: "mailto:support@ai4edu.example.com")!)
//                        .font(.footnote)
//                        .foregroundColor(.white)
//                }
//                .padding(.bottom, 20)
            }
            .padding()
            
            if showWebView, let ssoURL = APIService.shared.getSSOURL(returnURL: "ai4edu://callback") {
                SSOWebView(url: ssoURL, isPresented: $showWebView, onSuccessfulLogin: {
                    // Trigger login with animation via AppState
                    isLoggingIn = false
                    appState.login()
                }, onCancel: {
                    // Reset loading state when login is canceled
                    isLoggingIn = false
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showWebView)
                .zIndex(1) // Ensure WebView appears above other elements
            }
        }
        .onAppear {
            // Animate entry
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardOffset = 0
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
    
    private func handleSSOLogin() {
        isLoggingIn = true
        
        // Add visual feedback with slight delay
        withAnimation {
            // Simulate a short delay for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showWebView = true
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState())
            .preferredColorScheme(.dark)
        
        LoginView()
            .environmentObject(AppState())
            .preferredColorScheme(.light)
    }
}
