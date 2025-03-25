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
    case accessControl
    case chatHistory
    case settings
    case roster
}

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var currentTab: AppTab? = .dashboard
    @Published var currentWorkspace: Course?
    
    init() {
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
}