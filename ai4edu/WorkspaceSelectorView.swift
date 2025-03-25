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
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Workspace")
                        .font(.title2)
                        .bold()
                    
                    Text("Choose a workspace to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 10)
            
            // Divider
            Divider()
                .padding(.bottom, 10)
            
            // Workspaces Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 320))], spacing: 20) {
                    ForEach(workspaceRoles.keys.sorted(), id: \.self) { workspaceId in
                        if let role = workspaceRoles[workspaceId] {
                            WorkspaceRoleCard(
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
            .frame(maxHeight: 500)
            
            // Action Buttons
            HStack(spacing: 15) {
                Button(action: onDismiss) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    if let workspace = selectedWorkspace, let role = workspaceRoles[workspace] {
                        onSelectWorkspace(workspace, role)
                    }
                }) {
                    Text("Select")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedWorkspace != nil ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedWorkspace == nil)
            }
            .padding(.top, 10)
        }
        .padding(25)
        .frame(maxWidth: 700)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding()
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