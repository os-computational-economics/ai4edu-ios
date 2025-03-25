//
//  CourseCard.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//

import SwiftUI

struct CourseCard: View {
    let course: Course
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Button(action: {
            handleCourseClick()
        }) {
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(course.id)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Role badge
                    Text(course.role.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(roleColor(role: course.role))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Image("AI4EDULogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func roleColor(role: String) -> Color {
        switch role.lowercased() {
        case "admin":
            return Color.red
        case "teacher", "instructor":
            return Color.orange
        case "student":
            return Color.blue
        default:
            return Color.gray
        }
    }
    
    private func handleCourseClick() {
        // Save selected course
        CourseManager.shared.saveSelectedCourse(course)
        appState.currentWorkspace = course
        
        // Navigate to appropriate screen based on role
        if course.role == "admin" {
            appState.currentTab = .accessControl
        } else {
            appState.currentTab = .agents
        }
    }
}

struct CourseCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CourseCard(course: Course(id: "ECON235.F24", role: "student", name: "The Future Me"))
            CourseCard(course: Course(id: "CSDS344.S24", role: "admin", name: "Computer Security"))
            CourseCard(course: Course(id: "MATH380.S24", role: "teacher", name: "Probability"))
        }
        .environmentObject(AppState())
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 