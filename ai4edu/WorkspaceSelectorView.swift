//
//  WorkspaceSelectorView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI

struct WorkspaceSelectorView: View {
    let workspaceRoles: [String: String]
    let onSelectWorkspace: (String, String) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedWorkspace: String? = nil
    @State private var searchText: String = ""
    
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
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("YOUR WORKSPACES")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Select a workspace to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 5)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search workspaces", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 5)
            
            // Workspaces List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredWorkspaces, id: \.self) { workspaceId in
                        if let role = workspaceRoles[workspaceId] {
                            WorkspaceCard(
                                workspaceId: workspaceId,
                                role: role,
                                isSelected: selectedWorkspace == workspaceId
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedWorkspace = workspaceId
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 5)
            }
            .frame(maxHeight: .infinity)
            
            if filteredWorkspaces.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No workspaces found")
                        .font(.headline)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Text("CURRENT: \(appStateCurrentWorkspace())")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 5)
                
                // Settings section
                VStack(spacing: 10) {
                    Button(action: {
                        if let workspace = selectedWorkspace, let role = workspaceRoles[workspace] {
                            onSelectWorkspace(workspace, role)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right")
                            Text("Continue")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(selectedWorkspace != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(selectedWorkspace == nil)
                    
                    Button(action: {
                        // Sign out action
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Logout")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(20)
    }
    
    private func appStateCurrentWorkspace() -> String {
        return selectedWorkspace != nil ? formatWorkspaceName(selectedWorkspace!) : "None"
    }
    
    private func formatWorkspaceName(_ id: String) -> String {
        // Format the ID in a user-friendly way
        let parts = id.components(separatedBy: ".")
        if parts.count >= 2 {
            let courseCode = parts[0]
            let term = parts[1]
            return "\(courseCode)_\(term)"
        }
        
        return id
    }
}

struct WorkspaceCard: View {
    let workspaceId: String
    let role: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            // Course Icon
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(roleColor(for: role))
                .frame(width: 40, height: 40)
                .padding(.trailing, 10)
            
            // Course details
            VStack(alignment: .leading, spacing: 4) {
                Text(formatWorkspaceName(workspaceId))
                    .font(.headline)
                    .lineLimit(1)
                
                Text(role.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Role tag
            Text(role.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(roleColor(for: role))
                .cornerRadius(15)
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .padding(.leading, 5)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
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
        case "teacher":
            return .orange
        case "student":
            return .blue
        default:
            return .gray
        }
    }
}

struct WorkspaceSelectorModal: View {
    let workspaceRoles: [String: String]
    let onSelectWorkspace: (String, String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            
            WorkspaceSelectorView(
                workspaceRoles: workspaceRoles,
                onSelectWorkspace: onSelectWorkspace,
                onDismiss: onDismiss
            )
        }
    }
}

// MARK: - Preview
struct WorkspaceSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceSelectorModal(
            workspaceRoles: [
                "CSDS392.F24": "student",
                "ECON101.S25": "admin",
                "MATH228.S24": "student",
                "PHYS123.F24": "teacher"
            ],
            onSelectWorkspace: { _, _ in },
            onDismiss: { }
        )
        .previewLayout(.sizeThatFits)
    }
} 