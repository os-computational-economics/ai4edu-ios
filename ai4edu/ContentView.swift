//
//  ContentView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/23/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
                MainView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            appState.checkLoginStatus()
        }
    }
}

struct MainView: View {
    @EnvironmentObject private var appState: AppState
    @State private var workspaceRoles: [String: String] = [:]
    @State private var showWorkspaceSelector: Bool = false
    
    var body: some View {
        ZStack {
            DashboardView()
                .onAppear {
                    // Get workspace roles from token
                    workspaceRoles = TokenManager.shared.getWorkspaceRoles()
                    
                    if let accessToken = TokenManager.shared.getAccessToken(),
                       let refreshToken = TokenManager.shared.getRefreshToken() {
                        print("=== Current Tokens ===")
                        print("Access Token: \(accessToken)")
                        print("Refresh Token: \(refreshToken)")
                        print("====================")
                    }
                    
                    // If there's only one workspace, auto-select it
                    if workspaceRoles.count == 1, 
                       let workspaceId = workspaceRoles.keys.first,
                       let role = workspaceRoles[workspaceId] {
                        selectWorkspace(id: workspaceId, role: role)
                    }
                    // Don't show the workspace selector on login anymore
                }
            
            if showWorkspaceSelector {
                WorkspaceSelectorModal(
                    workspaceRoles: workspaceRoles,
                    onSelectWorkspace: { id, role in
                        selectWorkspace(id: id, role: role)
                        showWorkspaceSelector = false
                    },
                    onDismiss: {
                        showWorkspaceSelector = false
                    }
                )
                .transition(.opacity)
                .animation(.easeInOut, value: showWorkspaceSelector)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showWorkspaceSelector = true
                }) {
                    Label("Switch Workspace", systemImage: "rectangle.stack.fill")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: NSNotification.Name("ShowWorkspaceSelector"))
        ) { _ in
            showWorkspaceSelector = true
        }
    }
    
    private func selectWorkspace(id: String, role: String) {
        // Create the course to save, with name if available, otherwise use ID
        let courseName = workspaceNameFromId(id)
        let course = Course(id: id, role: role, name: courseName)
        
        // Save selected course
        CourseManager.shared.saveSelectedCourse(course)
        appState.currentWorkspace = course
        
        // Navigate to appropriate screen based on role
        if role.lowercased() == "admin" {
            appState.currentTab = .accessControl
        } else {
            appState.currentTab = .agents
        }
    }
    
    // Helper to get a friendly workspace name from ID
    private func workspaceNameFromId(_ id: String) -> String {
        // Try to find the existing course by ID to get its name
        let courses = CourseManager.shared.getCourses()
        if let existingCourse = courses.first(where: { $0.id == id }) {
            return existingCourse.name
        }
        
        // Format the ID in a user-friendly way if no name is available
        let parts = id.components(separatedBy: ".")
        if parts.count >= 2 {
            let courseCode = parts[0]
            let term = parts[1]
            return "\(courseCode) (\(term))"
        }
        
        return id
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
