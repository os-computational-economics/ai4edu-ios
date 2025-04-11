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
    @State private var hideTabBar: Bool = false
    
    var body: some View {
        Group {
            switch appState.currentTab {
            case .agents:
                AgentsView()
            case .roster:
                if let role = appState.currentWorkspace?.role,
                   role.lowercased() == "teacher" || role.lowercased() == "admin" {
                    RosterView()
                } else {
                    restrictedAccessView()
                }
            case .chatHistory:
                ThreadHistoryView()
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
            setupTabBarNotifications()
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
        workspaceRoles = TokenManager.shared.getWorkspaceRoles()
        
        courses = CourseManager.shared.getCourses()
        
        printWorkspaceRoles()
    }
    
    private func printWorkspaceRoles() {
        TokenManager.shared.debugPrintToken()
        
        if !workspaceRoles.isEmpty {
            for (workspaceId, role) in workspaceRoles.sorted(by: { $0.key < $1.key }) {
                print("  Workspace: \(workspaceId), Role: \(role.capitalized)")
            }
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
    @State private var hideTabBar: Bool = false
    
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
        .overlay(
            VStack {
                Spacer()
                if let role = appState.currentWorkspace?.role, 
                   role != "student" && !hideTabBar {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddNewAgent = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.blue))
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        )
        .onAppear {
            loadAgentsIfNeeded()
            setupTabBarNotifications()
        }
        .onChange(of: appState.currentWorkspace?.id) { oldId, newId in
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
    
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.text.rectangle.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 40)
            
            Text("No agents found")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("There are no agents available in this workspace. Please check back later or contact your instructor.")
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
        
        APIService.shared.fetchAgents(
            page: currentPage,
            pageSize: 10,
            workspaceId: formattedWorkspaceId
        ) { result in
            DispatchQueue.main.async {
                isLoadingMore = false
                
                switch result {
                case .success(let response):
                    let newAgents = response.data.items
                    
                    self.agents.append(contentsOf: newAgents)
                    
                    self.agents.sort { (agent1, agent2) -> Bool in
                        if agent1.status != agent2.status {
                            return agent1.status > agent2.status
                        } else {
                            return agent1.agentName.lowercased() < agent2.agentName.lowercased()
                        }
                    }
                    
                    self.totalAgents = response.data.total

                    hasMorePages = response.data.items.count >= 10 // Assuming page size is 10
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load more agents: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func loadAgents() {
        guard let workspaceId = appState.currentWorkspace?.id else { 
            return 
        }
        
        isLoading = true
        
        let formattedWorkspaceId = workspaceId.replacingOccurrences(of: ".", with: "_")
        
        let baseURL = "https://ai4edu-api.jerryang.org/v1/prod"
        let endpoint = "/admin/agents/agents"
        _ = "\(baseURL)\(endpoint)?page=\(currentPage)&page_size=10&workspace_id=\(formattedWorkspaceId)"
        
        
        APIService.shared.fetchAgents(
            page: currentPage,
            pageSize: 10,
            workspaceId: formattedWorkspaceId
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    
                    let sortedAgents = response.data.items.sorted { (agent1, agent2) -> Bool in
                        if agent1.status != agent2.status {
                            return agent1.status > agent2.status
                        } else {
                            return agent1.agentName.lowercased() < agent2.agentName.lowercased()
                        }
                    }
                    
                    self.agents = sortedAgents
                    self.totalAgents = response.data.total
                    
                    
                case .failure(let error):
                    
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
            
            HStack(spacing: 12) {
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
                
                if role != "student" {
                    Button(action: {
                        // TODO: Delete action
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
