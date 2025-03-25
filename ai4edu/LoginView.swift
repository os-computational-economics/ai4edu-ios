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
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Image("AI4EDULogo")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                    
                    Text("AI4EDU")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Sign in")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    Button(action: {
                        handleSSOLogin()
                    }) {
                        HStack {
                            Image("AI4EDULogo")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .cornerRadius(8)
                            
                            Text("Sign in with CWRU")
                                .fontWeight(.medium)
                                .padding(.horizontal)
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoggingIn)
                    .padding(.horizontal, 40)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(radius: 5)
                )
                .padding()
                
                Spacer()
            }
            
            if showWebView, let ssoURL = APIService.shared.getSSOURL(returnURL: "ai4edu://callback") {
                SSOWebView(url: ssoURL, isPresented: $showWebView, onSuccessfulLogin: {
                    appState.isLoggedIn = true
                })
                .transition(.opacity)
            }
        }
    }
    
    private func handleSSOLogin() {
        isLoggingIn = true
        showWebView = true
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState())
    }
}