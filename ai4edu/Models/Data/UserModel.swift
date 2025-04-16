//
//  APIService.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//

import Foundation

struct UserListResponse: Codable {
    let data: UserData
    let message: String
    let success: Bool
}

struct UserData: Codable {
    let items: [User]
    let total: Int
}

struct User: Identifiable, Codable {
    let userId: Int
    let email: String
    let firstName: String
    let lastName: String
    let studentId: String
    let workspaceRole: [String: String]
    
    var id: Int { userId }
    var fullName: String { "\(firstName) \(lastName)" }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case studentId = "student_id"
        case workspaceRole = "workspace_role"
    }
}