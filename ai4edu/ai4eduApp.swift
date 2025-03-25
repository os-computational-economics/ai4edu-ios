//
//  ai4eduApp.swift
//  ai4edu
//
//  Created by Sam Jin on 3/23/25.
//

import SwiftUI
import WebKit

@main
struct AI4EDUApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    // Handle deep links
                    if url.absoluteString.starts(with: "ai4edu://callback") {
                        if APIService.shared.handleSSOCallback(url: url) {
                            appState.isLoggedIn = true
                        }
                    }
                }
        }
    }
}
