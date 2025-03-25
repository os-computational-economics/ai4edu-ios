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
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("NAVIGATION")) {
                    NavigationLink(
                        destination: DashboardContentView(),
                        tag: AppTab.dashboard,
                        selection: $appState.currentTab
                    ) {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    .onTapGesture {
                        isPresented = false
                    }
                    
                    if let workspace = appState.currentWorkspace, !workspace.id.isEmpty {
                        NavigationLink(
                            destination: AgentsView(),
                            tag: AppTab.agents,
                            selection: $appState.currentTab
                        ) {
                            Label("Agents", systemImage: "person.text.rectangle")
                        }
                        .onTapGesture {
                            isPresented = false
                        }
                        
                        NavigationLink(
                            destination: ThreadHistoryView(),
                            tag: AppTab.chatHistory,
                            selection: $appState.currentTab
                        ) {
                            Label("Chat History", systemImage: "bubble.left.and.bubble.right")
                        }
                        .onTapGesture {
                            isPresented = false
                        }
                        
                        if appState.currentWorkspace?.role == "admin" {
                            NavigationLink(
                                destination: AccessControlView(),
                                tag: AppTab.accessControl,
                                selection: $appState.currentTab
                            ) {
                                Label("Access Control", systemImage: "lock.shield")
                            }
                            .onTapGesture {
                                isPresented = false
                            }
                        }
                    }
                }
                
                // Display all workspaces from JWT directly in sidebar
                if !workspaceRoles.isEmpty {
                    Section(header: Text("WORKSPACES")) {
                        ForEach(workspaceRoles.keys.sorted(), id: \.self) { workspaceId in
                            if let role = workspaceRoles[workspaceId] {
                                let isCurrentWorkspace = appState.currentWorkspace?.id == workspaceId
                                
                                Button(action: {
                                    selectWorkspace(id: workspaceId, role: role)
                                    isPresented = false
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
                                .listRowBackground(isCurrentWorkspace ? Color.accentColor.opacity(0.1) : Color.clear)
                            }
                        }
                    }
                }
                
                Section(header: Text("SETTINGS")) {
                    Button(action: {
                        appState.logout()
                        isPresented = false
                    }) {
                        Label("Logout", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        // Show workspace selector
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ShowWorkspaceSelector"),
                            object: nil
                        )
                        isPresented = false
                    }) {
                        Label("Switch Workspace", systemImage: "rectangle.stack.fill")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                // Load workspace roles from token
                workspaceRoles = TokenManager.shared.getWorkspaceRoles()
            }
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

struct SidebarMobileView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarMobileView(isPresented: .constant(true))
            .environmentObject(AppState())
    }
} 