//
//  ContentView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/23/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isAnimating: Bool = false
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
                MainView()
                    .environmentObject(appState)
                    .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            } else {
                LoginView()
                    .environmentObject(appState)
                    .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .leading)),
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isLoggedIn)
        .onAppear {
            appState.checkLoginStatus()
        }
    }
}
