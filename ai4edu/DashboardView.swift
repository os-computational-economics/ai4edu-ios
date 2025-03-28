//
//  DashboardView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @State private var courses: [Course] = []
    @State private var workspaceRoles: [String: String] = [:]
    @State private var showTokenInformation: Bool = false
    
    var body: some View {
        // Display the appropriate content based on the currently selected tab
        Group {
            switch appState.currentTab {
            case .agents:
                AgentsView()
            case .roster:
                // Only show roster if the user has teacher or admin role
                if let role = appState.currentWorkspace?.role,
                   role.lowercased() == "teacher" || role.lowercased() == "admin" {
                    RosterView()
                } else {
                    // Show access restricted view for students
                    restrictedAccessView()
                }
            case .chatHistory:
                ThreadHistoryView()
            case .accessControl:
                AccessControlView()
            case .none:
                AgentsView()
            case .some(.dashboard):
                AgentsView()
            case .some(.settings):
                AgentsView()
            }
        }
        .onAppear {
            loadData()
            TokenManager.shared.debugPrintToken()
        }
    }
    
    // View to show when access is restricted
    private func restrictedAccessView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding(.top, 40)
            
            Text("Access Restricted")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("The roster view is only available to teachers and administrators.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    private func loadData() {
        // Get workspace roles from token
        workspaceRoles = TokenManager.shared.getWorkspaceRoles()
        
        // Load courses, which will be updated with roles from the token
        courses = CourseManager.shared.getCourses()
        
        printWorkspaceRoles()
    }
    
    private func printWorkspaceRoles() {
        // Use the new improved debug print function that shows everything
        TokenManager.shared.debugPrintToken()
        
        // Also print workspace roles (which are accessed directly by the app)
        if !workspaceRoles.isEmpty {
            print("\n=== AVAILABLE WORKSPACE ROLES ===")
            for (workspaceId, role) in workspaceRoles.sorted(by: { $0.key < $1.key }) {
                print("  Workspace: \(workspaceId), Role: \(role.capitalized)")
            }
            print("================================\n")
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showTokens: Bool
    @State private var workspaceRoles: [String: String] = [:]
    
    init(showTokens: Bool = false) {
        self._showTokens = State(initialValue: showTokens)
    }
    
    var body: some View {
        List {
            
            // Display all workspaces from JWT directly in sidebar
            if !workspaceRoles.isEmpty {
                Section(header: Text("YOUR WORKSPACES")) {
                    ForEach(workspaceRoles.keys.sorted(), id: \.self) { workspaceId in
                        if let role = workspaceRoles[workspaceId] {
                            let isCurrentWorkspace = appState.currentWorkspace?.id == workspaceId
                            
                            Button(action: {
                                selectWorkspace(id: workspaceId, role: role)
                            }) {
                                HStack {
                                    Text(formatWorkspaceName(workspaceId))
                                        .fontWeight(isCurrentWorkspace ? .bold : .regular)
                                    
                                    Spacer()
                                    
                                    Text(role.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(roleColor(for: role))
                                        .cornerRadius(4)
                                }
                            }
                            .foregroundColor(.primary)
                            .background(isCurrentWorkspace ? Color.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Show current workspace features if one is selected
            if let workspace = appState.currentWorkspace, !workspace.id.isEmpty {
                Section(header: Text("CURRENT: \(workspace.name)")) {
                    NavigationLink(
                        destination: AgentsView(),
                        tag: AppTab.agents,
                        selection: $appState.currentTab
                    ) {
                        Label("Agents", systemImage: "person.text.rectangle")
                    }
                    
                    // Only show Roster for teachers and admins
                    if workspace.role == "teacher" || workspace.role == "admin" {
                        NavigationLink(
                            destination: RosterView(),
                            tag: AppTab.roster,
                            selection: $appState.currentTab
                        ) {
                            Label("Roster", systemImage: "person.3")
                        }
                    }
                    
                    NavigationLink(
                        destination: ThreadHistoryView(),
                        tag: AppTab.chatHistory,
                        selection: $appState.currentTab
                    ) {
                        Label("Chat History", systemImage: "bubble.left.and.bubble.right")
                    }
                    
                    if workspace.role == "admin" {
                        NavigationLink(
                            destination: AccessControlView(),
                            tag: AppTab.accessControl,
                            selection: $appState.currentTab
                        ) {
                            Label("Access Control", systemImage: "lock.shield")
                        }
                    }
                }
            }
            
            Section(header: Text("SETTINGS")) {
                Button(action: {
                    appState.logout()
                }) {
                    Label("Logout", systemImage: "arrow.right.square")
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    showTokens.toggle()
                }) {
                    HStack {
                        Label("Show Tokens", systemImage: "key.fill")
                        Spacer()
                        Image(systemName: showTokens ? "chevron.up" : "chevron.down")
                    }
                }
                
                if showTokens {
                    VStack(alignment: .leading, spacing: 10) {
                        // Decoded Token Information
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
                        
                        // Raw Token Display
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
                    .padding(.top, 8)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
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

struct AgentsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var agents: [Agent] = []
    @State private var isLoading: Bool = true
    @State private var isLoadingMore: Bool = false
    @State private var currentPage: Int = 1
    @State private var totalAgents: Int = 0
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var hasMorePages: Bool = true
    @State private var showingAddNewAgent: Bool = false
    @State private var showAgentDetail: Bool = false
    @State private var currentWorkspaceId: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading && agents.isEmpty {
                Spacer()
                ProgressView("Loading agents...")
                    .padding()
                Spacer()
            } else if agents.isEmpty {
                emptyStateView()
            } else {
                agentsTableView()
            }
        }
        .onAppear {
            loadAgentsIfNeeded()
        }
        .onChange(of: appState.currentWorkspace?.id) { newId in
            // Reload agents when workspace changes
            if let newWorkspaceId = newId, newWorkspaceId != currentWorkspaceId {
                currentWorkspaceId = newWorkspaceId
                resetAndReload()
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingAddNewAgent) {
            // In a real implementation, you would create an AddAgentView here
            VStack {
                Text("Add New Agent")
                    .font(.title)
                    .padding()
                
                Text("This is a placeholder for the add agent form.")
                    .padding()
                
                Button("Close") {
                    showingAddNewAgent = false
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .padding()
        }
    }
    
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.text.rectangle.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 40)
            
            Text("No agents found")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("There are no agents available in this workspace. Please check back later or contact your administrator.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            if appState.currentWorkspace?.role != "student" {
                Button(action: {
                    showingAddNewAgent = true
                }) {
                    Label("Add New Agent", systemImage: "plus")
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func agentsTableView() -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(agents) { agent in
                        AgentCard(agent: agent, role: appState.currentWorkspace?.role ?? "student")
                    }
                    
                    if isLoadingMore {
                        ProgressView("Loading more...")
                            .padding()
                    } else if !hasMorePages && !agents.isEmpty {
                        VStack(spacing: 8) {
                            Divider()
                            Text("End of list - No more agents")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 12)
                        }
                    }
                    
                    // Only show this if we might have more pages
                    if hasMorePages {
                        Color.clear
                            .frame(height: 50)
                            .onAppear {
                                loadMoreIfNeeded()
                            }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 8)
            }
            .refreshable {
                resetAndReload()
            }
            
            // Restored agent count text with smaller size
            HStack {
                Text("Showing \(agents.count) of \(totalAgents) agent\(totalAgents == 1 ? "" : "s")")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(8)
    }
    
    private func loadAgentsIfNeeded() {
        if let workspaceId = appState.currentWorkspace?.id, workspaceId != currentWorkspaceId {
            currentWorkspaceId = workspaceId
            resetAndReload()
        } else if agents.isEmpty {
            loadAgents()
        }
    }
    
    private func resetAndReload() {
        currentPage = 1
        agents = []
        hasMorePages = true
        loadAgents()
    }
    
    private func loadMoreIfNeeded() {
        if !isLoadingMore && hasMorePages {
            currentPage += 1
            loadMoreAgents()
        }
    }
    
    private func loadMoreAgents() {
        guard let workspaceId = appState.currentWorkspace?.id, !isLoadingMore else { return }
        
        isLoadingMore = true
        
        let formattedWorkspaceId = workspaceId.replacingOccurrences(of: ".", with: "_")
        print("📱 Fetching more agents for page \(currentPage), workspace: \(formattedWorkspaceId)")
        
        APIService.shared.fetchAgents(
            page: currentPage,
            pageSize: 10,
            workspaceId: formattedWorkspaceId
        ) { result in
            DispatchQueue.main.async {
                isLoadingMore = false
                
                switch result {
                case .success(let response):
                    // Get the new agents
                    let newAgents = response.data.items
                    
                    // Add new agents to existing list
                    self.agents.append(contentsOf: newAgents)
                    
                    // Re-sort all agents to ensure correct ordering
                    self.agents.sort { (agent1, agent2) -> Bool in
                        if agent1.status != agent2.status {
                            // Sort by status (active first)
                            return agent1.status > agent2.status
                        } else {
                            // If status is the same, sort alphabetically by name
                            return agent1.agentName.lowercased() < agent2.agentName.lowercased()
                        }
                    }
                    
                    self.totalAgents = response.data.total
                    print("📱 Successfully loaded additional \(response.data.items.count) agents")
                    print("📱 Total agents now: \(self.agents.count) of \(self.totalAgents)")
                    
                    // Check if there might be more pages
                    hasMorePages = response.data.items.count >= 10 // Assuming page size is 10
                    
                case .failure(let error):
                    print("📱 Error loading more agents: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load more agents: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func loadAgents() {
        guard let workspaceId = appState.currentWorkspace?.id else { 
            print("📱 ERROR: No workspace ID available")
            return 
        }
        
        isLoading = true
        
        let formattedWorkspaceId = workspaceId.replacingOccurrences(of: ".", with: "_")
        print("📱 AGENTS - Starting fetch for workspace: \(formattedWorkspaceId)")
        print("📱 AGENTS - Page: \(currentPage), PageSize: 10")
        
        // Construct the URL for debugging purposes
        let baseURL = "https://ai4edu-api.jerryang.org/v1/prod"
        let endpoint = "/admin/agents/agents"
        let debugURL = "\(baseURL)\(endpoint)?page=\(currentPage)&page_size=10&workspace_id=\(formattedWorkspaceId)"
        print("📱 AGENTS - Request URL: \(debugURL)")
        
        if let accessToken = TokenManager.shared.getAccessToken() {
            print("📱 AGENTS - Using access token: \(accessToken.prefix(15))...")
        } else {
            print("📱 AGENTS - WARNING: No access token available")
        }
        
        APIService.shared.fetchAgents(
            page: currentPage,
            pageSize: 10,
            workspaceId: formattedWorkspaceId
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                print("📱 AGENTS - Response received")
                
                switch result {
                case .success(let response):
                    print("📱 AGENTS - SUCCESS! Message: \(response.message)")
                    print("📱 AGENTS - Success flag: \(response.success)")
                    print("📱 AGENTS - Total agents: \(response.data.total)")
                    print("📱 AGENTS - Items count: \(response.data.items.count)")
                    
                    if !response.data.items.isEmpty {
                        print("📱 AGENTS - First agent: \(response.data.items[0].agentName) (ID: \(response.data.items[0].agentId))")
                    }
                    
                    // Sort agents - active agents first, then disabled agents
                    let sortedAgents = response.data.items.sorted { (agent1, agent2) -> Bool in
                        if agent1.status != agent2.status {
                            // Sort by status (active first)
                            return agent1.status > agent2.status
                        } else {
                            // If status is the same, sort alphabetically by name
                            return agent1.agentName.lowercased() < agent2.agentName.lowercased()
                        }
                    }
                    
                    self.agents = sortedAgents
                    self.totalAgents = response.data.total
                    
                    if self.agents.isEmpty {
                        print("📱 AGENTS - API returned success but with empty agents array")
                    }
                    
                case .failure(let error):
                    print("📱 AGENTS - ERROR: \(error.localizedDescription)")
                    
                    if let urlError = error as? URLError {
                        print("📱 AGENTS - URLError code: \(urlError.code.rawValue)")
                        switch urlError.code {
                        case .notConnectedToInternet:
                            print("📱 AGENTS - Device is not connected to internet")
                        case .timedOut:
                            print("📱 AGENTS - Request timed out")
                        case .cannotFindHost:
                            print("📱 AGENTS - Cannot find host")
                        default:
                            print("📱 AGENTS - Other URLError")
                        }
                    }
                    
                    self.errorMessage = "Failed to load agents: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
}

struct AgentCard: View {
    let agent: Agent
    let role: String
    @State private var navigateToAgentDetail: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top section: Name and status
            VStack(alignment: .leading, spacing: 6) {
                Text(agent.agentName)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Circle()
                        .fill(agent.status == 1 ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(agent.status == 1 ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Bottom section: Buttons
            HStack(spacing: 12) {
                // Chat button - always show with a filled style
                Button(action: {
                    navigateToAgentDetail = true
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Chat")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Delete button - disabled for teachers, hidden for students
                if role != "student" {
                    Button(action: {
                        // Delete action
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(role == "teacher" ? Color.gray.opacity(0.2) : Color.red.opacity(0.1))
                        .foregroundColor(role == "teacher" ? Color.gray : Color.red)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(role == "teacher" ? Color.gray.opacity(0.3) : Color.red.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .disabled(role == "teacher") // Disable for teachers
                }
                
                // Edit button - only for admins
                if role == "admin" {
                    Button(action: {
                        // Edit action
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .background(
            NavigationLink(
                destination: AgentDetailView(agent: agent)
                    .navigationBarHidden(true),
                isActive: $navigateToAgentDetail
            ) {
                EmptyView()
            }
        )
    }
}

struct ChatHistoryPlaceholderView: View {
    var body: some View {
        Text("Chat History Placeholder")
            .font(.largeTitle)
    }
}

struct AccessControlView: View {
    var body: some View {
        Text("Access Control")
            .font(.largeTitle)
    }
}

struct WorkspaceRolesView: View {
    let workspaceRoles: [String: String]
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display available workspaces in a grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200))], spacing: 12) {
                ForEach(workspaceRoles.keys.sorted(), id: \.self) { workspaceId in
                    if let role = workspaceRoles[workspaceId] {
                        let isCurrentWorkspace = appState.currentWorkspace?.id == workspaceId
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(formatWorkspaceName(workspaceId))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if isCurrentWorkspace {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            
                            HStack {
                                Text(workspaceId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(role.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(roleColor(for: role))
                                    .cornerRadius(4)
                            }
                            
                            if !isCurrentWorkspace {
                                Button(action: {
                                    selectWorkspace(id: workspaceId, role: role)
                                }) {
                                    Text("Select")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 2)
                            } else {
                                Text("Current")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isCurrentWorkspace ? Color.green : Color.gray.opacity(0.3), lineWidth: isCurrentWorkspace ? 2 : 1)
                        )
                    }
                }
            }
            .padding(.horizontal)
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

// Token expiration status view component
struct ExpirationStatusView: View {
    let expirationDate: Date
    
    var body: some View {
        let now = Date()
        let isExpired = now > expirationDate
        
        VStack(alignment: .trailing, spacing: 4) {
            Text(formatDate(expirationDate))
                .font(.caption)
                .bold()
            
            Text(isExpired ? "EXPIRED" : "VALID")
                .font(.caption)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isExpired ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

struct RosterView: View {
    @EnvironmentObject private var appState: AppState
    @State private var users: [User] = []
    @State private var isLoading: Bool = true
    @State private var isLoadingMore: Bool = false
    @State private var currentPage: Int = 1
    @State private var totalUsers: Int = 0
    @State private var hasMorePages: Bool = true
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var currentWorkspaceId: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading && users.isEmpty {
                Spacer()
                ProgressView("Loading roster...")
                    .padding()
                Spacer()
            } else if users.isEmpty {
                emptyStateView()
            } else {
                rosterListView()
            }
        }
        .onAppear {
            loadUsersIfNeeded()
        }
        .onChange(of: appState.currentWorkspace?.id) { newId in
            // Reload users when workspace changes
            if let newWorkspaceId = newId, newWorkspaceId != currentWorkspaceId {
                currentWorkspaceId = newWorkspaceId
                resetAndReload()
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 40)
            
            Text("No users found")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("There are no users enrolled in this workspace yet.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func rosterListView() -> some View {
        VStack(spacing: 0) {
            // Simplified table header - only show the required columns
            HStack {
                Text("User ID")
                    .fontWeight(.semibold)
                    .frame(width: 80, alignment: .leading)
                
                Text("Student ID")
                    .fontWeight(.semibold)
                    .frame(width: 100, alignment: .leading)
                
                Text("Name")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(Color(UIColor.secondarySystemBackground))
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(users) { user in
                        // Simplified row showing only required fields
                        HStack {
                            Text("\(user.userId)")
                                .font(.subheadline)
                                .frame(width: 80, alignment: .leading)
                            
                            Text(user.studentId)
                                .font(.subheadline)
                                .frame(width: 100, alignment: .leading)
                            
                            Text(user.fullName)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            Divider(),
                            alignment: .bottom
                        )
                    }
                    
                    if isLoadingMore {
                        ProgressView("Loading more...")
                            .padding()
                    } else if !hasMorePages && !users.isEmpty {
                        VStack(spacing: 8) {
                            Divider()
                            Text("End of list - No more users")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 12)
                        }
                    }
                    
                    // Only show this if we might have more pages
                    if hasMorePages {
                        Color.clear
                            .frame(height: 50)
                            .onAppear {
                                loadMoreIfNeeded()
                            }
                    }
                }
            }
            .refreshable {
                resetAndReload()
            }
            
            // Footer with user count
            HStack {
                Text("Showing \(users.count) of \(totalUsers) user\(totalUsers == 1 ? "" : "s")")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal)
            .background(Color(UIColor.secondarySystemBackground))
        }
    }
    
    private func loadUsersIfNeeded() {
        if let workspaceId = appState.currentWorkspace?.id, workspaceId != currentWorkspaceId {
            currentWorkspaceId = workspaceId
            resetAndReload()
        } else if users.isEmpty {
            loadUserList()
        }
    }
    
    private func resetAndReload() {
        currentPage = 1
        users = []
        hasMorePages = true
        loadUserList()
    }
    
    private func loadMoreIfNeeded() {
        if !isLoadingMore && hasMorePages {
            currentPage += 1
            loadMoreUsers()
        }
    }
    
    private func loadMoreUsers() {
        guard let workspaceId = appState.currentWorkspace?.id, !isLoadingMore else { return }
        
        isLoadingMore = true
        
        let formattedWorkspaceId = workspaceId.replacingOccurrences(of: ".", with: "_")
        print("📱 Fetching more users for page \(currentPage), workspace: \(formattedWorkspaceId)")
        
        APIService.shared.fetchUserList(
            page: currentPage,
            pageSize: 10,
            workspaceId: formattedWorkspaceId
        ) { result in
            DispatchQueue.main.async {
                isLoadingMore = false
                
                switch result {
                case .success(let response):
                    // Add new users to existing list
                    users.append(contentsOf: response.data.items)
                    totalUsers = response.data.total
                    print("📱 Successfully loaded additional \(response.data.items.count) users")
                    print("📱 Total users now: \(users.count) of \(totalUsers)")
                    
                    // Check if there might be more pages
                    hasMorePages = response.data.items.count >= 10 // Assuming page size is 10
                    
                case .failure(let error):
                    print("📱 Error loading more users: \(error.localizedDescription)")
                    errorMessage = "Failed to load more users: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func loadUserList() {
        guard let workspaceId = appState.currentWorkspace?.id else { return }
        
        isLoading = true
        
        let formattedWorkspaceId = workspaceId.replacingOccurrences(of: ".", with: "_")
        print("📱 Fetching users for workspace: \(formattedWorkspaceId)")
        
        APIService.shared.fetchUserList(
            page: currentPage,
            pageSize: 10,
            workspaceId: formattedWorkspaceId
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    users = response.data.items
                    totalUsers = response.data.total
                    hasMorePages = response.data.items.count >= 10
                    
                    print("📱 Successfully loaded \(response.data.items.count) users")
                    print("📱 Total users available: \(response.data.total)")
                    
                    if users.isEmpty {
                        print("📱 API returned success but with empty users array")
                    }
                    
                case .failure(let error):
                    print("📱 Error loading users: \(error.localizedDescription)")
                    errorMessage = "Failed to load users: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}

// Preview providers
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.currentWorkspace = Course(id: "CSDS392.F24", role: "student", name: "iOS App Development")
        appState.currentTab = .agents
        
        return DashboardView()
            .environmentObject(appState)
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.currentWorkspace = Course(id: "CSDS392.F24", role: "student", name: "iOS App Development")
        
        return NavigationView {
            SidebarView(showTokens: true)
                .environmentObject(appState)
        }
    }
} 
