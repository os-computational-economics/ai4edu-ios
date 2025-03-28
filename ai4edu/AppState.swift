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
    
    func login() {
        // Update login state with a slight delay to allow for animations
        // This method should be called after successful login
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                self.isLoggedIn = true
                self.currentWorkspace = CourseManager.shared.getSelectedCourse()
            }
        }
    }
    
    func logout() {
        // First animate the transition
        withAnimation {
            self.isLoggedIn = false
            self.currentWorkspace = nil
        }
        
        // Then clear actual tokens after animation starts
        TokenManager.shared.clearTokens()
        CourseManager.shared.saveSelectedCourse(Course(id: "", role: "", name: ""))
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        // Save the preference to UserDefaults
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}
