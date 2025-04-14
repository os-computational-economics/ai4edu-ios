//
//  ChatResponseModels.swift
//  ai4edu
//
//  Created by Sam Jin on 4/13/25.
//

import Foundation

struct ThreadResponse: Codable {
    let data: ThreadData
    let message: String
    let success: Bool
}

struct ThreadData: Codable {
    let threadId: String
    
    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id"
    }
}

struct ThreadMessagesWrapper: Codable {
    let data: ThreadMessagesData
    let message: String
    let success: Bool
}

struct ThreadMessagesData: Codable {
    let threadId: String
    let messages: [ThreadMessage]
    
    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id"
        case messages
    }
}

struct ThreadMessage: Codable {
    let threadId: String
    let createdAt: String
    let msgId: String
    let userId: String
    let role: String
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id"
        case createdAt = "created_at"
        case msgId = "msg_id"
        case userId = "user_id"
        case role
        case content
    }
}

struct ThreadInfo: Codable, Identifiable {
    let threadId: String
    let createdAt: String
    let agentId: String
    let userId: Int
    let workspaceId: String
    let agentName: String
    
    var id: String { threadId }
    
    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id"
        case createdAt = "created_at"
        case agentId = "agent_id"
        case userId = "user_id"
        case workspaceId = "workspace_id"
        case agentName = "agent_name"
    }
}

struct ThreadsListWrapper: Codable {
    let data: ThreadsListData
    let message: String
    let success: Bool
}

struct ThreadsListData: Codable {
    let items: [ThreadInfo]
    let total: Int
}

struct SingleAgentResponse: Codable {
    let data: Agent
    let message: String
    let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case data, message, success
    }
} 