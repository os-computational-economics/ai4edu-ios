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

struct MainView: View {
    @EnvironmentObject private var appState: AppState
    @State private var workspaceRoles: [String: String] = [:]
    @State private var showWorkspaceSelector: Bool = false
    @State private var selectedTab: Int = 0 // 0 = Main, 1 = Settings
    @State private var navigateToAgentDetail: Bool = false
    @State private var agentForContinue: Agent? = nil
    @State private var threadIdForContinue: String? = nil
    @State private var hideTabBar: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if appState.currentWorkspace != nil && !appState.currentWorkspace!.id.isEmpty {
                    VStack(spacing: 0) {
                        if let workspace = appState.currentWorkspace, !hideTabBar {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(roleColor(for: workspace.role).opacity(0.2))
                                        .frame(width: 26, height: 26)
                                    
                                    Text(String(formatWorkspaceName(workspace.id).prefix(1)).uppercased())
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(roleColor(for: workspace.role))
                                }
                                
                                Text(formatWorkspaceName(workspace.id))
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button(action: {
                                    showWorkspaceSelector = true
                                }) {
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color(.systemGray6).opacity(0.5))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6).opacity(0.3))
                        }
                        
                        if selectedTab == 0 {
                            mainTabContent
                        } else {
                            settingsTabContent
                        }
                        
                        if !hideTabBar {
                            HStack {
                                Spacer()
                                Button(action: { selectedTab = 0 }) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "square.grid.2x2")
                                            .font(.system(size: 16))
                                        Text("Main")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(selectedTab == 0 ? .blue : .gray)
                                }
                                
                                Spacer()
                                
                                Button(action: { selectedTab = 1 }) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "gear")
                                            .font(.system(size: 16))
                                        Text("Settings")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(selectedTab == 1 ? .blue : .gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 5)
                            .background(Color(.systemBackground))
                            .overlay(
                                Divider(),
                                alignment: .top
                            )
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            Image("AI4EDULogo")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .cornerRadius(10)
                            
                            Text("AI4EDU")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        
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
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                        
                        if selectedTab == 0 {
                            workspacesTabContent
                        } else {
                            settingsTabContent
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: { selectedTab = 0 }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 16))
                                    Text("Workspaces")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(selectedTab == 0 ? .blue : .gray)
                            }
                            
                            Spacer()
                            
                            Button(action: { selectedTab = 1 }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 16))
                                    Text("Settings")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(selectedTab == 1 ? .blue : .gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 5)
                        .background(Color(.systemBackground))
                        .overlay(
                            Divider(),
                            alignment: .top
                        )
                    }
                    .onAppear {
                        workspaceRoles = TokenManager.shared.getWorkspaceRoles()
                    
                    if workspaceRoles.count == 1, 
                       let workspaceId = workspaceRoles.keys.first,
                       let role = workspaceRoles[workspaceId] {
                        selectWorkspace(id: workspaceId, role: role)
                    }
                    }
                }
            
            if showWorkspaceSelector {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showWorkspaceSelector = false
                        }
                    
                    VStack(spacing: 0) {
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
            .onReceive(NotificationCenter.default.publisher(
                for: NSNotification.Name("ShowAgentDetailWithThread"))
            ) { notification in
                
                DispatchQueue.main.async {
                    if let agent = notification.userInfo?["agent"] as? Agent,
                       let threadId = notification.userInfo?["threadId"] as? String {
                        
                        self.agentForContinue = agent
                        self.threadIdForContinue = threadId
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.navigateToAgentDetail = true
                        }
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: Group {
                        if let agent = agentForContinue, let threadId = threadIdForContinue {
                            AgentDetailView(agent: agent, initialThreadId: threadId)
                                .navigationBarHidden(true)
                        }
                    },
                    isActive: $navigateToAgentDetail
                ) {
                    EmptyView()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .onAppear {
            workspaceRoles = TokenManager.shared.getWorkspaceRoles()
            
            setupTabBarNotifications()
            
            if let accessToken = TokenManager.shared.getAccessToken(),
               let refreshToken = TokenManager.shared.getRefreshToken() {
                print("=== Current Tokens ===")
                print("Access Token: \(accessToken)")
                print("Refresh Token: \(refreshToken)")
                print("====================")
            }
        }
    }
    
    private var mainTabContent: some View {
        VStack(spacing: 0) {
            if !hideTabBar {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        NavigationTabButton(
                            title: "Agents",
                            icon: "person.text.rectangle.fill",
                            isSelected: appState.currentTab == .agents,
                            action: { appState.currentTab = .agents }
                        )
                        
                        if let role = appState.currentWorkspace?.role,
                           role.lowercased() == "teacher" || role.lowercased() == "admin" {
                            NavigationTabButton(
                                title: "Roster",
                                icon: "person.2.fill",
                                isSelected: appState.currentTab == .roster,
                                action: { appState.currentTab = .roster }
                            )
                        }
                        
                        NavigationTabButton(
                            title: "Chat History",
                            icon: "bubble.left.and.bubble.right.fill",
                            isSelected: appState.currentTab == .chatHistory,
                            action: { appState.currentTab = .chatHistory }
                        )
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                Divider()
            }
            
            DashboardView()
        }
    }
    
    // Settings tab content
    private var settingsTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("SETTINGS")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("APPEARANCE")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                    
                    HStack {
                        Image(systemName: appState.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(appState.isDarkMode ? .purple : .orange)
                            .font(.system(size: 18))
                            .frame(width: 25, height: 25)
                        
                        Text("Dark Mode")
                            .font(.headline)
                        
                        Spacer()
                        
                        Toggle("", isOn: $appState.isDarkMode)
                            .labelsHidden()
                            .onChange(of: appState.isDarkMode) { 
                                appState.toggleDarkMode()
                            }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    appState.logout()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                            .font(.system(size: 18))
                            .frame(width: 25, height: 25)
                        
                        Text("Logout")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                
                TokensView()
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("ABOUT THE APP")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                        .padding(.top, 20)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI4EDU")
                                .font(.headline)
                            
                            Text("Version 1.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image("AI4EDULogo")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGray6).opacity(0.3))
    }
    
    private var workspacesTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("YOUR WORKSPACES")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                ForEach(workspaceRoles.keys.sorted(), id: \.self) { workspaceId in
                    if let role = workspaceRoles[workspaceId] {
                        HomeWorkspaceCard(
                            workspaceId: workspaceId,
                            role: role,
                            onTap: {
                                selectWorkspace(id: workspaceId, role: role)
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                
                    Text("GETTING STARTED")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
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
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGray6).opacity(0.3))
    }
    
    private func selectWorkspace(id: String, role: String) {
        let courseName = formatWorkspaceName(id)
        let course = Course(id: id, role: role, name: courseName)
        
        CourseManager.shared.saveSelectedCourse(course)
        appState.currentWorkspace = course
    }
    
    private func formatWorkspaceName(_ id: String) -> String {
        let courses = CourseManager.shared.getCourses()
        if let existingCourse = courses.first(where: { $0.id == id }) {
            return existingCourse.name
        }
        
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
    
    private func setupTabBarNotifications() {
        NotificationCenter.default.removeObserver(self)
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HideTabBar"),
            object: nil,
            queue: .main) { _ in
                withAnimation {
                    self.hideTabBar = true
                }
            }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowTabBar"),
            object: nil,
            queue: .main) { _ in
                withAnimation {
                    self.hideTabBar = false
                }
            }
    }
}

struct IntegratedHomeView: View {
    let workspaceRoles: [String: String]
    let onSelectWorkspace: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 15) {
                HStack {
                    Image("AI4EDULogo")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(10)
                    
                    Text("AI4EDU")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
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
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))
            
            ScrollView {
                LazyVStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("YOUR WORKSPACES")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal)
                        
                        ForEach(workspaceRoles.keys.sorted(), id: \.self) { workspaceId in
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
                    .padding(.vertical)
                    
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
        let parts = id.components(separatedBy: ".")
        if parts.count >= 2 {
            let courseCode = parts[0]
            let term = parts[1]
            return "\(courseCode) (\(term))"
        }
        
        return id
    }
}

struct NavigationTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}

struct WorkspaceSelectorRow: View {
    let workspaceId: String
    let role: String
    let isCurrentWorkspace: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(roleColor(for: role).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(String(formatWorkspaceName(workspaceId).prefix(2)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(roleColor(for: role))
                }
                
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
                ZStack {
                    Circle()
                        .fill(roleColor(for: role).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(String(formatWorkspaceName(workspaceId).prefix(2)).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(roleColor(for: role))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatWorkspaceName(workspaceId))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(role.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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

struct TokensView: View {
    @State private var showTokens: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                showTokens.toggle()
            }) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(width: 25, height: 25)
                    
                    Text("Show Tokens")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: showTokens ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            if showTokens {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Token Information:")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.top, 5)
                    
                    if let jwtData = TokenManager.shared.decodeToken() {
                        VStack(alignment: .leading) {
                            Text(jwtData.formattedString())
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(4)
                            
                            if !jwtData.workspaceRoles.isEmpty {
                                Divider()
                                    .padding(.vertical, 5)
                                
                                Text("Workspace Roles:")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(jwtData.workspaceRoles.sorted(by: { $0.key < $1.key }), id: \.key) { workspace, role in
                                        HStack {
                                            Text(workspace)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(role.capitalized)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(4)
                            }
                        }
                    } else {
                        Text("Unable to decode token")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    Text("Access Token (Raw):")
                        .font(.caption)
                        .fontWeight(.bold)
                    
                    if let accessToken = TokenManager.shared.getAccessToken() {
                        ScrollView {
                            Text(accessToken)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(4)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 100)
                    } else {
                        Text("No access token")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("Refresh Token (Raw):")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.top, 5)
                    
                    if let refreshToken = TokenManager.shared.getRefreshToken() {
                        ScrollView {
                            Text(refreshToken)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(4)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 100)
                    } else {
                        Text("No refresh token")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
