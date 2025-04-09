//
//  AgentModel.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import Foundation

// MARK: - Agent Response

struct AgentsListResponse: Codable {
    let data: AgentData
    let message: String
    let success: Bool
}

struct AgentData: Codable {
    let items: [Agent]
    let total: Int
}

// MARK: - Agent Model

struct Agent: Identifiable, Codable {
    let agentId: String
    let agentName: String
    let workspaceId: String
    let voice: Bool
    let allowModelChoice: Bool
    let model: String
    let agentFiles: [String: String]
    let status: Int  // 1 = Active, 0 = Disabled
    let createdAt: String
    let creator: String
    let updatedAt: String
    let systemPrompt: String
    
    var id: String { agentId }
    
    enum CodingKeys: String, CodingKey {
        case agentId = "agent_id"
        case agentName = "agent_name"
        case workspaceId = "workspace_id"
        case voice, model
        case allowModelChoice = "allow_model_choice"
        case agentFiles = "agent_files"
        case status
        case createdAt = "created_at"
        case creator
        case updatedAt = "updated_at"
        case systemPrompt = "system_prompt"
    }
}

// MARK: - Mock Data

extension Agent {
    static var mockAgents: [Agent] = [
        Agent(
            agentId: "95a125ba-d403-4c05-8117-fc9c94b77e79",
            agentName: "The Future Me",
            workspaceId: "ECON330_F24",
            voice: false,
            allowModelChoice: false,
            model: "",
            agentFiles: ["651f1b90-5f1b-47df-b1ad-42e1a18b8d7c": "Activity-Consulting with Future Me.pdf"],
            status: 1,
            createdAt: "2024-11-04 03:00:00.150061",
            creator: "",
            updatedAt: "2024-12-13 20:03:16.307421",
            systemPrompt: "System prompt for Future Me"
        ),
        Agent(
            agentId: "f4633d96-c7a3-43ab-9479-9b749744a4d3",
            agentName: "Prof Chat for Final Exam Preparation",
            workspaceId: "ECON330_F24",
            voice: false,
            allowModelChoice: false,
            model: "",
            agentFiles: ["7699382e-5280-4726-b8b3-395a84949acf": "module0_a_introduction.pdf"],
            status: 1,
            createdAt: "2024-10-14 18:47:04.987191",
            creator: "",
            updatedAt: "2024-11-29 03:38:04.416172",
            systemPrompt: "System prompt for Prof Chat"
        ),
        Agent(
            agentId: "f6881a28-7dd7-48af-9467-bb21f15f9901",
            agentName: "Marketing Analyst",
            workspaceId: "ECON330_F24",
            voice: false,
            allowModelChoice: false,
            model: "",
            agentFiles: ["651f1b90-5f1b-47df-b1ad-42e1a18b8d7c": "Activity-Consulting with Future Me.pdf"],
            status: 0,
            createdAt: "2024-11-04 03:02:47.457140",
            creator: "",
            updatedAt: "2024-11-21 02:36:41.790771",
            systemPrompt: "System prompt for Marketing Analyst"
        )
    ]
    
    static func findAgent(by id: String) -> Agent? {

        if let cachedAgents = UserDefaults.standard.object(forKey: "cachedAgents") as? Data {
            if let agents = try? JSONDecoder().decode([Agent].self, from: cachedAgents) {
                let found = agents.first(where: { $0.agentId == id })
                return found
            } else {
                print("🔍 Failed to decode cached agents")
            }
        } else {
            print("🔍 No cached agents found in UserDefaults")
        }
        
        let found = mockAgents.first(where: { $0.agentId == id })
        return found
    }
} 