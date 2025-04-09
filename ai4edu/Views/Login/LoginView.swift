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
            
            VStack {
                Spacer()
                
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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            buttonScale = 0.95
                        }
                        
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
                
            }
            .padding()
            
            if showWebView, let ssoURL = APIService.shared.getSSOURL(returnURL: "ai4edu://callback") {
                SSOWebView(url: ssoURL, isPresented: $showWebView, onSuccessfulLogin: {
                    isLoggingIn = false
                    appState.login()
                }, onCancel: {
                    isLoggingIn = false
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showWebView)
                .zIndex(1) 
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardOffset = 0
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
    
    private func handleSSOLogin() {
        isLoggingIn = true
        
        withAnimation {
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
