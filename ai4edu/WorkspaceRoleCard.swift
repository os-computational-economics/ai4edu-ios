//
//  WorkspaceRoleCard.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI

struct WorkspaceRoleCard: View {
    let workspaceId: String
    let role: String
    let name: String
    let isSelected: Bool
    
    init(workspaceId: String, role: String, isSelected: Bool) {
        self.workspaceId = workspaceId
        self.role = role
        self.isSelected = isSelected
        self.name = Self.formatWorkspaceName(from: workspaceId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Workspace title
            Text(name)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
            
            // Workspace ID
            Text(workspaceId)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                .lineLimit(1)
            
            Spacer()
            
            // Role badge
            HStack {
                Spacer()
                
                Text(role.capitalized)
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(roleBackgroundColor.opacity(isSelected ? 1.0 : 0.9))
                    )
                    .foregroundColor(.white)
            }
        }
        .frame(width: 180, height: 100)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.05), radius: 5, x: 0, y: 2)
    }
    
    private var roleBackgroundColor: Color {
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
    
    private static func formatWorkspaceName(from id: String) -> String {
        // Format the ID in a user-friendly way
        let parts = id.components(separatedBy: ".")
        if parts.count >= 2 {
            let courseCode = parts[0]
            let term = parts[1]
            
            // Format course code with space if it has a subject and number
            var formattedCourse = courseCode
            if let index = courseCode.firstIndex(where: { $0.isNumber }) {
                let subjectCode = courseCode[..<index]
                let courseNumber = courseCode[index...]
                formattedCourse = "\(subjectCode) \(courseNumber)"
            }
            
            return "\(formattedCourse)\n\(term)"
        }
        
        return id
    }
}

struct WorkspaceRoleCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                WorkspaceRoleCard(workspaceId: "CSDS392.F24", role: "student", isSelected: false)
                WorkspaceRoleCard(workspaceId: "ECON101.S25", role: "admin", isSelected: true)
            }
            
            HStack(spacing: 20) {
                WorkspaceRoleCard(workspaceId: "MATH228.S24", role: "student", isSelected: false)
                WorkspaceRoleCard(workspaceId: "PHYS123.F24", role: "teacher", isSelected: false)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .previewLayout(.sizeThatFits)
    }
} 