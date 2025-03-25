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
    @State private var selectedTab: AppTab = .agents
    
    var body: some View {
        ZStack {
            if appState.currentWorkspace != nil && !appState.currentWorkspace!.id.isEmpty {
                // Main App Content with Integrated Navigation
                VStack(spacing: 0) {
                    // Header with workspace info and actions
                    VStack(spacing: 8) {
                        HStack {
                            // Workspace info
                            HStack(spacing: 10) {
                                let workspace = appState.currentWorkspace!
                                
                                // Workspace icon
                                ZStack {
                                    Circle()
                                        .fill(roleColor(for: workspace.role).opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    
                                    Text(String(formatWorkspaceName(workspace.id).prefix(2)).uppercased())
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(roleColor(for: workspace.role))
                                }
                                
                                Text(formatWorkspaceName(workspace.id))
                                    .font(.headline)
                                
                                Text(workspace.role.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(roleColor(for: workspace.role))
                                    .cornerRadius(10)
                            }
                            .padding(8)
                            .background(Color(.systemGray6).opacity(0.7))
                            .cornerRadius(10)
                            .onTapGesture {
                                showWorkspaceSelector = true
                            }
                            
                            Spacer()
                            
                            // User actions
                            Button(action: {
                                appState.logout()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                }
                                .font(.footnote)
                                .padding(8)
                                .background(Color(.systemGray6).opacity(0.7))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        // Navigation tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                NavigationTabButton(
                                    title: "Agents",
                                    icon: "person.text.rectangle.fill",
                                    isSelected: appState.currentTab == .agents,
                                    action: { appState.currentTab = .agents }
                                )
                                
                                NavigationTabButton(
                                    title: "Roster",
                                    icon: "person.2.fill",
                                    isSelected: appState.currentTab == .roster,
                                    action: { appState.currentTab = .roster }
                                )
                                
                                NavigationTabButton(
                                    title: "Chat History",
                                    icon: "bubble.left.and.bubble.right.fill",
                                    isSelected: appState.currentTab == .chatHistory,
                                    action: { appState.currentTab = .chatHistory }
                                )
                                
                                if appState.currentWorkspace?.role.lowercased() == "admin" {
                                    NavigationTabButton(
                                        title: "Access Control",
                                        icon: "lock.shield.fill",
                                        isSelected: appState.currentTab == .accessControl,
                                        action: { appState.currentTab = .accessControl }
                                    )
                                }
                                
                                // Add any other needed tabs here
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                    }
                    
                    // Main content area - dashboard view
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
                        }
                }
            } else {
                // Landing page when no workspace is selected
                IntegratedHomeView(
                    workspaceRoles: workspaceRoles,
                    onSelectWorkspace: { id, role in
                        selectWorkspace(id: id, role: role)
                    }
                )
                .onAppear {
                    // Get workspace roles from token
                    workspaceRoles = TokenManager.shared.getWorkspaceRoles()
                    
                    // If there's only one workspace, auto-select it
                    if workspaceRoles.count == 1, 
                       let workspaceId = workspaceRoles.keys.first,
                       let role = workspaceRoles[workspaceId] {
                        selectWorkspace(id: workspaceId, role: role)
                    }
                }
            }
            
            // Workspace selector overlay
            if showWorkspaceSelector {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showWorkspaceSelector = false
                    }
                
                // Workspace selector with list of available workspaces
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Select Workspace")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showWorkspaceSelector = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Workspace list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(workspaceRoles.keys.sorted(), id: \.self) { workspaceId in
                                if let role = workspaceRoles[workspaceId] {
                                    WorkspaceSelectorRow(
                                        workspaceId: workspaceId,
                                        role: role,
                                        isCurrentWorkspace: appState.currentWorkspace?.id == workspaceId,
                                        onSelect: {
                                            selectWorkspace(id: workspaceId, role: role)
                                            showWorkspaceSelector = false
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 400)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showWorkspaceSelector)
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
        let courseName = formatWorkspaceName(id)
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

// Integrated Home View without sidebar
struct IntegratedHomeView: View {
    let workspaceRoles: [String: String]
    let onSelectWorkspace: (String, String) -> Void
    @State private var selectedTab = 0
    @State private var searchText = ""
    
    var filteredWorkspaces: [String] {
        if searchText.isEmpty {
            return workspaceRoles.keys.sorted()
        } else {
            return workspaceRoles.keys.filter { 
                formatWorkspaceName($0).lowercased().contains(searchText.lowercased()) 
            }.sorted()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 15) {
                // App logo and title
                HStack {
                    Image("AI4EDULogo")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(10)
                    
                    Text("AI4EDU")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Logout button
                    Button(action: {
                        // Logout action
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .font(.subheadline)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // Welcome message
                VStack(alignment: .leading, spacing: 5) {
                    Text("Welcome to AI4EDU")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Select a workspace to get started with your AI learning assistant")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search workspaces", text: $searchText)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            // Tabs
            HStack(spacing: 0) {
                TabButton(title: "All Workspaces", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "Recent", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
            }
            .padding(.horizontal)
            .background(Color(UIColor.systemBackground))
            
            // Divider
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))
            
            // Content
            ScrollView {
                LazyVStack(spacing: 15) {
                    // Section - Your Workspaces
                    VStack(alignment: .leading, spacing: 15) {
                        Text("YOUR WORKSPACES")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal)
                        
                        if filteredWorkspaces.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                                
                                Text("No workspaces found")
                                    .font(.headline)
                                
                                if !searchText.isEmpty {
                                    Text("Try a different search term")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            ForEach(filteredWorkspaces, id: \.self) { workspaceId in
                                if let role = workspaceRoles[workspaceId] {
                                    HomeWorkspaceCard(
                                        workspaceId: workspaceId,
                                        role: role,
                                        onTap: {
                                            onSelectWorkspace(workspaceId, role)
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // Section - Getting Started
                    VStack(alignment: .leading, spacing: 15) {
                        Text("GETTING STARTED")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal)
                        
                        VStack(spacing: 15) {
                            FeatureCard(
                                icon: "person.text.rectangle.fill",
                                title: "Talk to Learning Assistants",
                                description: "Access AI assistants trained on your course materials"
                            )
                            
                            FeatureCard(
                                icon: "doc.fill",
                                title: "Submit Assignments",
                                description: "Complete and submit coursework with intelligent feedback"
                            )
                            
                            FeatureCard(
                                icon: "chart.bar.fill",
                                title: "Track Progress",
                                description: "Monitor your learning journey and improvement"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGray6).opacity(0.5))
        }
    }
    
    private func formatWorkspaceName(_ id: String) -> String {
        // Format the ID in a user-friendly way
        let parts = id.components(separatedBy: ".")
        if parts.count >= 2 {
            let courseCode = parts[0]
            let term = parts[1]
            return "\(courseCode) (\(term))"
        }
        
        return id
    }
}

// Navigation tab button for the main view
struct NavigationTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(20)
        }
    }
}

// Workspace selector row for the workspace picker
struct WorkspaceSelectorRow: View {
    let workspaceId: String
    let role: String
    let isCurrentWorkspace: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Workspace icon
                ZStack {
                    Circle()
                        .fill(roleColor(for: role).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(String(formatWorkspaceName(workspaceId).prefix(2)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(roleColor(for: role))
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatWorkspaceName(workspaceId))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(role.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isCurrentWorkspace {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrentWorkspace ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatWorkspaceName(_ id: String) -> String {
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
        case "admin": return .red
        case "teacher", "instructor": return .orange
        case "student": return .blue
        default: return .gray
        }
    }
}

// Existing components below
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                ZStack {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.clear)
                    
                    if isSelected {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HomeWorkspaceCard: View {
    let workspaceId: String
    let role: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Workspace icon
                ZStack {
                    Circle()
                        .fill(roleColor(for: role).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(String(formatWorkspaceName(workspaceId).prefix(2)).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(roleColor(for: role))
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatWorkspaceName(workspaceId))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(role.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Role badge and action indicator
                HStack {
                    Text(role.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(roleColor(for: role))
                        .cornerRadius(12)
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatWorkspaceName(_ id: String) -> String {
        // Format the ID in a user-friendly way
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

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 45, height: 45)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
