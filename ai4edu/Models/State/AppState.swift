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
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.isLoggedIn = TokenManager.shared.isLoggedIn()
        self.currentWorkspace = CourseManager.shared.getSelectedCourse()
    }
    
    func checkLoginStatus() {
        self.isLoggedIn = TokenManager.shared.isLoggedIn()
    }
    
    func login() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                self.isLoggedIn = true
                self.currentWorkspace = CourseManager.shared.getSelectedCourse()
            }
        }
    }
    
    func logout() {
        withAnimation {
            self.isLoggedIn = false
            self.currentWorkspace = nil
        }
        
        TokenManager.shared.clearTokens()
        CourseManager.shared.saveSelectedCourse(Course(id: "", role: "", name: ""))
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}
