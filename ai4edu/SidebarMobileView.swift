//
//  SidebarMobileView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI

struct SidebarMobileView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isPresented: Bool
    @State private var workspaceRoles: [String: String] = [:]
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with current workspace info
            if let workspace = appState.currentWorkspace, !workspace.id.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("CURRENT: \(formatWorkspaceName(workspace.id))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        // Workspace icon
                        ZStack {
                            Circle()
                                .fill(roleColor(for: workspace.role).opacity(0.2))
                                .frame(width: 42, height: 42)
                            
                            Text(String(formatWorkspaceName(workspace.id).prefix(2)).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(roleColor(for: workspace.role))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatWorkspaceName(workspace.id))
                                .font(.headline)
                            
                            HStack {
                                Text(workspace.role.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(roleColor(for: workspace.role))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
            
            // Navigation List
            List {
                // Navigation Section
                Section {
                    if let workspace = appState.currentWorkspace, !workspace.id.isEmpty {
                        NavigationRow(
                            icon: "person.text.rectangle.fill",
                            title: "Agents",
                            isSelected: appState.currentTab == .agents,
                            action: {
                                appState.currentTab = .agents
                                isPresented = false
                            }
                        )
                        
                        NavigationRow(
                            icon: "person.2.fill",
                            title: "Roster",
                            isSelected: appState.currentTab == .roster,
                            action: {
                                appState.currentTab = .roster
                                isPresented = false
                            }
                        )
                        
                        NavigationRow(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "Chat History",
                            isSelected: appState.currentTab == .chatHistory,
                            action: {
                                appState.currentTab = .chatHistory
                                isPresented = false
                            }
                        )
                        
                        if workspace.role.lowercased() == "admin" {
                            NavigationRow(
                                icon: "lock.shield.fill",
                                title: "Access Control",
                                isSelected: appState.currentTab == .accessControl,
                                action: {
                                    appState.currentTab = .accessControl
                                    isPresented = false
                                }
                            )
                        }
                    }
                } header: {
                    Text("NAVIGATION")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Workspaces Section
                if !workspaceRoles.isEmpty {
                    Section {
                        ForEach(workspaceRoles.keys.sorted(), id: \.self) { workspaceId in
                            if let role = workspaceRoles[workspaceId], 
                               workspaceId != appState.currentWorkspace?.id {
                                Button(action: {
                                    selectWorkspace(id: workspaceId, role: role)
                                    isPresented = false
                                }) {
                                    HStack(spacing: 12) {
                                        // Workspace icon
                                        ZStack {
                                            Circle()
                                                .fill(roleColor(for: role).opacity(0.2))
                                                .frame(width: 32, height: 32)
                                            
                                            Text(String(formatWorkspaceName(workspaceId).prefix(2)).uppercased())
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(roleColor(for: role))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(formatWorkspaceName(workspaceId))
                                                .font(.system(size: 15))
                                                .foregroundColor(.primary)
                                            
                                            Text(role.capitalized)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Button(action: {
                            // Show workspace selector
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowWorkspaceSelector"),
                                object: nil
                            )
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                
                                Text("Browse All Workspaces")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 4)
                    } header: {
                        Text("YOUR WORKSPACES")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Settings Section
                Section {
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                                .frame(width: 24, height: 24)
                            
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        // Show tokens
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                                .frame(width: 24, height: 24)
                            
                            Text("Show Tokens")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("SETTINGS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .alert(isPresented: $showLogoutConfirmation) {
            Alert(
                title: Text("Confirm Logout"),
                message: Text("Are you sure you want to log out of your account?"),
                primaryButton: .destructive(Text("Logout")) {
                    appState.logout()
                    isPresented = false
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            // Load workspace roles from token
            workspaceRoles = TokenManager.shared.getWorkspaceRoles()
        }
    }
    
    private func selectWorkspace(id: String, role: String) {
        let courseName = formatWorkspaceName(id)
        let course = Course(id: id, role: role, name: courseName)
        
        // Save selected course and update app state
        CourseManager.shared.saveSelectedCourse(course)
        appState.currentWorkspace = course
        
        // Navigate to appropriate screen based on role
        if role.lowercased() == "admin" {
            appState.currentTab = .accessControl
        } else {
            appState.currentTab = .agents
        }
    }
    
    private func formatWorkspaceName(_ id: String) -> String {
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
    
    private func roleColor(for role: String) -> Color {
        switch role.lowercased() {
        case "admin":
            return .red
        case "teacher", "instructor":
            return .orange
        case "student":
            return .blue
        default:
            return .gray
        }
    }
}

struct NavigationRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(isSelected ? Color.blue.opacity(0.1) : Color.clear)
    }
}

struct SidebarMobileView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarMobileView(isPresented: .constant(true))
            .environmentObject(AppState())
    }
} 
