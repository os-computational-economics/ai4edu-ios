//
//  AppState.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//


import Foundation
import SwiftUI

enum AppTab {
    case dashboard
    case agents
    case chatHistory
    case settings
    case roster
}

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var currentTab: AppTab? = .dashboard
    @Published var currentWorkspace: Course?
    @Published var isDarkMode: Bool = false
    
    init() {
        // Load dark mode preference from UserDefaults
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.isLoggedIn = TokenManager.shared.isLoggedIn()
        self.currentWorkspace = CourseManager.shared.getSelectedCourse()
    }
    
    func checkLoginStatus() {
        self.isLoggedIn = TokenManager.shared.isLoggedIn()
    }
    
    func logout() {
        TokenManager.shared.clearTokens()
        self.isLoggedIn = false
        self.currentWorkspace = nil
        CourseManager.shared.saveSelectedCourse(Course(id: "", role: "", name: ""))
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        // Save the preference to UserDefaults
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}
