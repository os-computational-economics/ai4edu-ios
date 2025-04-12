//
//  ChatService.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import Foundation
import Combine
import SwiftUI

class ChatService {
    static let shared = ChatService()
    
    private let baseURL = "https://ai4edu-api.jerryang.org/v1/prod"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Thread Management
    
    func createNewThread(agentId: String, workspaceId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "/user/get_new_thread"
        
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = [
            URLQueryItem(name: "agent_id", value: agentId),
            URLQueryItem(name: "workspace_id", value: workspaceId)
        ]
        
        guard let url = urlComponents?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("📱 CHAT-API - WARNING: No access token available for authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 CHAT-API - HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 CHAT-API - Raw Response: \(responseString)")
                }
                
                let response = try JSONDecoder().decode(ThreadResponse.self, from: data)
                completion(.success(response.data.threadId))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getThreadMessages(threadId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        let endpoint = "/admin/threads/get_thread/\(threadId)"
        
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(APIError.noData))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 CHAT-API - HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 CHAT-API - Response: \(responseString.prefix(200))...")
                }
                
                let response = try JSONDecoder().decode(ThreadMessagesWrapper.self, from: data)
                
                let messages = response.data.messages.map { apiMessage -> Message in
                    return Message(
                        id: apiMessage.msgId,
                        content: apiMessage.content,
                        align: apiMessage.role == "human" ? "end" : "start",
                        user_id: apiMessage.userId,
                        MsgId: apiMessage.msgId,
                        role: apiMessage.role
                    )
                }
                
                DispatchQueue.main.async {
                    completion(.success(messages))
                }
            } catch {
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("📱 CHAT-API - Key '\(key.stringValue)' not found: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("📱 CHAT-API - Value of type \(type) not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("📱 CHAT-API - Type mismatch for type \(type): \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("📱 CHAT-API - Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("📱 CHAT-API - Unknown decoding error")
                    }
                }
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getThreadsList(page: Int = 1, pageSize: Int = 10, workspaceId: String, completion: @escaping (Result<(threads: [ThreadInfo], total: Int), Error>) -> Void) {
        let endpoint = "/admin/threads/get_thread_list"
        
        let role = getUserRoleForWorkspace(workspaceId: workspaceId)
        let userId = (role == "admin" || role == "teacher") ? "-1" : getCurrentUserID()
        
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "workspace_id", value: workspaceId),
            URLQueryItem(name: "user_id", value: userId)
        ]
        
        guard let url = urlComponents?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(APIError.noData))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                httpResponse.allHeaderFields.forEach { key, value in
                    print("📱 CHAT-API -   \(key): \(value)")
                }
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 CHAT-API - Raw Response: \(responseString)")
                }
                
                let response = try JSONDecoder().decode(ThreadsListWrapper.self, from: data)
                
                if response.data.items.isEmpty {
                    print("📱 CHAT-API - No threads found")
                } else if let firstThread = response.data.items.first {
                    print("📱 CHAT-API - First thread: \(firstThread.threadId), Agent: \(firstThread.agentName)")
                }
                
                let threads = response.data.items
                let total = response.data.total
                
                DispatchQueue.main.async {
                    completion(.success((threads: threads, total: total)))
                }
            } catch {
                
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("📱 CHAT-API - Key '\(key.stringValue)' not found: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("📱 CHAT-API - Value of type \(type) not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("📱 CHAT-API - Type mismatch for type \(type): \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("📱 CHAT-API - Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("📱 CHAT-API - Unknown decoding error")
                    }
                }
                
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Chat Communication
    
    func sendMessage(message: String, threadId: String, agentId: String, workspaceId: String, previousMessages: [[String: Any]]? = nil, completion: @escaping (Result<ChatResponse, Error>) -> Void) {
        let endpoint = "/user/stream_chat"
        
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let userId = getCurrentUserID()
        
        let model = "openai"
        let voice = false
        
        var messagesDict = [String: [String: String]]()
        
        if let previousMessages = previousMessages {
            for (index, msgDict) in previousMessages.enumerated() {
                if let role = msgDict["role"] as? String,
                   let content = msgDict["content"] as? String {
                    messagesDict["\(index)"] = ["role": role, "content": content]
                }
            }
        } else {
            messagesDict["0"] = ["role": "user", "content": message]
        }
        
        let chatMessage = [
            "dynamic_auth_code": "random",
            "messages": messagesDict,
            "thread_id": threadId,
            "workspace_id": workspaceId,
            "provider": model,
            "user_id": userId,
            "agent_id": agentId,
            "voice": voice
        ] as [String: Any]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(APIError.networkError))
            return
        }
        
        // Serialize the request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: chatMessage)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                httpResponse.allHeaderFields.forEach { key, value in
                    print("📱 CHAT-API -   \(key): \(value)")
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.noData))
                }
                return
            }
            
            if let dataString = String(data: data, encoding: .utf8) {
                
                let events = dataString.components(separatedBy: "\n")
                    .filter { !$0.isEmpty && $0.hasPrefix("data: ") }
                
                print("📱 CHAT-API - Found \(events.count) events in response")
                
                if let lastEvent = events.last?.dropFirst(6) {
                        let jsonData = Data(lastEvent.utf8)
                        
                        if let responseDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                           let responseText = responseDict["response"] as? String {
                            
                            let msgId = responseDict["msg_id"] as? String ?? UUID().uuidString
                            
                            var sources: [Source]? = nil
                            if let sourceArray = responseDict["source"] as? [[String: Any]], !sourceArray.isEmpty {
                                sources = []
                                for (_, sourceItem) in sourceArray.enumerated() {
                                    if let fileId = sourceItem["file_id"] as? String,
                                       let fileName = sourceItem["file_name"] as? String,
                                       let page = sourceItem["page"] as? Int {
                                        let source = Source(fileId: fileId, fileName: fileName, page: page)
                                        sources?.append(source)
                                    }
                                }
                            }
                            
                            let chatResponse = ChatResponse(
                                threadId: threadId,
                                messageId: msgId,
                                content: responseText,
                                sources: sources
                            )
                            
                            DispatchQueue.main.async {
                                completion(.success(chatResponse))
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(.failure(APIError.decodingError))
                            }
                        }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(APIError.noData))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.decodingError))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - AsyncStream message
    func streamMessage(message: String, threadId: String, agentId: String, workspaceId: String, previousMessages: [[String: Any]]? = nil) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let endpoint = "/user/stream_chat"
            
            guard let url = URL(string: baseURL + endpoint) else {
                continuation.finish(throwing: APIError.invalidURL)
                return
            }
            
            let userId = getCurrentUserID()
            
            var messagesDict = [String: [String: String]]()
            
            if let previousMessages = previousMessages {
                for (index, msgDict) in previousMessages.enumerated() {
                    if let role = msgDict["role"] as? String,
                       let content = msgDict["content"] as? String {
                        messagesDict["\(index)"] = ["role": role, "content": content]
                    }
                }
            } else {
                messagesDict["0"] = ["role": "user", "content": message]
            }
            
            let chatMessage = [
                "dynamic_auth_code": "random",
                "messages": messagesDict,
                "thread_id": threadId,
                "workspace_id": workspaceId,
                "provider": "openai",
                "user_id": userId,
                "agent_id": agentId,
                "voice": false
            ] as [String: Any]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let accessToken = getAccessToken() {
                request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
            } else {
                continuation.finish(throwing: APIError.networkError)
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: chatMessage)
                request.httpBody = jsonData
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📱 CHAT-API - [Stream] Request payload: \(jsonString)")
                }
            } catch {
                continuation.finish(throwing: error)
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    httpResponse.allHeaderFields.forEach { key, value in
                        print("📱 CHAT-API - [Stream]   \(key): \(value)")
                    }
                }
                
                guard let data = data else {
                    continuation.finish(throwing: APIError.noData)
                    return
                }
                
                
                if let dataString = String(data: data, encoding: .utf8) {
                    
                    let events = dataString.components(separatedBy: "\n")
                        .filter { !$0.isEmpty && $0.hasPrefix("data: ") }
                    
                    
                    var lastResponse = ""
                    var messageId = ""
                    var eventCounter = 0
                    
                    for eventString in events {
                        eventCounter += 1
                        let event = eventString.dropFirst(6)
                        
                            let jsonData = Data(event.utf8)
                            if let responseDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                               let responseText = responseDict["response"] as? String {
                                
                                lastResponse = responseText
                                if let msgId = responseDict["msg_id"] as? String {
                                    messageId = msgId
                                }
                                
                                continuation.yield(lastResponse)
                            } else {
                                if let jsonString = String(data: jsonData, encoding: .utf8) {
                                    print("📱 CHAT-API - [Stream] Raw JSON: \(jsonString)")
                                }
                            }
                    }
                    
                    if !lastResponse.isEmpty {
                        continuation.finish()
                    } else {
                        continuation.finish(throwing: APIError.decodingError)
                    }
                } else {
                    continuation.finish(throwing: APIError.decodingError)
                }
            }
            
            task.resume()
        }
    }
    
    func streamMessageWithCallback(
        message: String,
        threadId: String,
        agentId: String,
        workspaceId: String,
        previousMessages: [[String: Any]]? = nil,
        onChunk: @escaping (String) -> Void,
        onCompletion: @escaping (Result<ChatResponse, Error>) -> Void
    ) {
        let endpoint = "/user/stream_chat"
        
        guard let url = URL(string: baseURL + endpoint) else {
            onCompletion(.failure(APIError.invalidURL))
            return
        }
        
        let userId = getCurrentUserID()
        
        var messagesDict = [String: [String: String]]()
        
        if let previousMessages = previousMessages {
            for (index, msgDict) in previousMessages.enumerated() {
                if let role = msgDict["role"] as? String,
                   let content = msgDict["content"] as? String {
                    messagesDict["\(index)"] = ["role": role, "content": content]
                }
            }
        } else {
            messagesDict["0"] = ["role": "user", "content": message]
        }
        
        let chatMessage = [
            "dynamic_auth_code": "random",
            "messages": messagesDict,
            "thread_id": threadId,
            "workspace_id": workspaceId,
            "provider": "openai",
            "user_id": userId,
            "agent_id": agentId,
            "voice": false
        ] as [String: Any]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            onCompletion(.failure(APIError.networkError))
            return
        }
        
        // Serialize the request body
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: chatMessage)
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📱 CHAT-API - [StreamCallback] Request payload: \(jsonString)")
            }
        } catch {
            onCompletion(.failure(error))
            return
        }
        
        let delegate = StreamDelegate(onChunk: onChunk, onCompletion: onCompletion, threadId: threadId)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    // MARK: - Streaming Delegate for Processing Chunks
    
    private class StreamDelegate: NSObject, URLSessionDataDelegate {
        private var buffer = Data()
        private var responseText = ""
        private var previousLength = 0
        private var messageId = ""
        private var sources: [Source]? = nil
        private var eventCount = 0
        private let onChunk: (String) -> Void
        private let onCompletion: (Result<ChatResponse, Error>) -> Void
        private let threadId: String
        
        init(onChunk: @escaping (String) -> Void, onCompletion: @escaping (Result<ChatResponse, Error>) -> Void, threadId: String) {
            self.onChunk = onChunk
            self.onCompletion = onCompletion
            self.threadId = threadId
            super.init()
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            buffer.append(data)
            
            if let dataString = String(data: buffer, encoding: .utf8) {
                let lines = dataString.components(separatedBy: "\n")
                
                for line in lines where line.hasPrefix("data: ") {
                    eventCount += 1
                    let event = line.dropFirst(6)
                    
                    do {
                        if let data = event.data(using: .utf8),
                           let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            
                            if let msgId = responseDict["msg_id"] as? String {
                                messageId = msgId
                            }
                            
                            if let text = responseDict["response"] as? String {
                                if eventCount % 100 == 0 || eventCount < 10 {
                                    print("📱 CHAT-API - [Stream] Event #\(eventCount): \"\(text.prefix(30))...\"")
                                }
                                
                                if text.count > previousLength {
                                    let newContent = String(text.dropFirst(previousLength))
                                    if !newContent.isEmpty {
                                        responseText = text
                                        onChunk(text)
                                        previousLength = text.count
                                    }
                                }
                            }
                            
                            if let sourceArray = responseDict["source"] as? [[String: Any]], !sourceArray.isEmpty {
                                sources = []
                                for (_, sourceItem) in sourceArray.enumerated() {
                                    if let fileId = sourceItem["file_id"] as? String,
                                       let fileName = sourceItem["file_name"] as? String,
                                       let page = sourceItem["page"] as? Int {
                                        let source = Source(fileId: fileId, fileName: fileName, page: page)
                                        sources?.append(source)
                                    }
                                }
                            }
                        }
                    } catch {
                        print("📱 CHAT-API - [Stream] Error parsing event: \(error)")
                    }
                }
                
                if dataString.hasSuffix("\n") {
                    buffer = Data()
                } else if let lastNewlineRange = dataString.range(of: "\n", options: .backwards) {
                    let partialLine = dataString[lastNewlineRange.upperBound...]
                    if let partialData = String(partialLine).data(using: .utf8) {
                        buffer = partialData
                    }
                }
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error {
                onCompletion(.failure(error))
                return
            }
            
            
            if !responseText.isEmpty {
                let chatResponse = ChatResponse(
                    threadId: threadId,
                    messageId: messageId.isEmpty ? UUID().uuidString : messageId,
                    content: responseText,
                    sources: sources
                )
                
                onCompletion(.success(chatResponse))
            } else {
                onCompletion(.failure(APIError.decodingError))
            }
        }
    }
    
    // MARK: - Feedback
    
    func submitRating(threadId: String, messageId: String, rating: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        let endpoint = "/feedback/feedback"
        
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let feedback = [
            "thread_id": threadId,
            "message_id": messageId,
            "rating": rating
        ] as [String: Any]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("📱 CHAT-API - WARNING: No access token available for authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: feedback)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    func getCurrentUserID() -> String {
        let userId = TokenManager.shared.getUserID()
        if userId != "-1" {
            return userId
        }
        
        if let studentId = UserDefaults.standard.string(forKey: "studentId"),
           !studentId.isEmpty && studentId != "unknown" {
            return studentId
        }
        
        return "-1"
    }
    
    func getCurrentStudentID() -> String {
        return getCurrentUserID()
    }
    
    private func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: "accessToken") ?? TokenManager.shared.getAccessToken()
    }
    
    private func getUserRoleForWorkspace(workspaceId: String) -> String {
        let workspaceRoles = TokenManager.shared.getWorkspaceRoles()
        return workspaceRoles[workspaceId]?.lowercased() ?? "student"
    }

    func getAgentDetails(agentId: String, completion: @escaping (Result<Agent, Error>) -> Void) {
        guard !agentId.isEmpty else {
            completion(.failure(NSError(domain: "ChatService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Agent ID is empty"])))
            return
        }
        
        let endpoint = "/admin/agents/agent/\(agentId)"
        let apiUrl = baseURL + endpoint
        
        print("📱 AGENT-API - Requesting agent details from: \(apiUrl)")
        
        guard let url = URL(string: apiUrl) else {
            completion(.failure(NSError(domain: "ChatService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("📱 AGENT-API - WARNING: No access token available for authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("📱 AGENT-API - Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 AGENT-API - HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("📱 AGENT-API - No data received from server")
                completion(.failure(NSError(domain: "ChatService", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received from server"])))
                return
            }
            
            // Log the full response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📱 AGENT-API - Full Response: \(jsonString)")
            }
            
            do {
                let agentResponse = try JSONDecoder().decode(SingleAgentResponse.self, from: data)
                
                // Debug - print agent files information
                print("📱 AGENT-API - Decoded agent files: \(agentResponse.data.agentFiles)")
                print("📱 AGENT-API - Files count: \(agentResponse.data.agentFiles.count)")
                
                completion(.success(agentResponse.data))
            } catch {
                print("📱 AGENT-API - Decoding error: \(error)")
                
                // Additional debug - try to parse manually to see files
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let data = json["data"] as? [String: Any],
                   let files = data["agent_files"] as? [String: String] {
                    print("📱 AGENT-API - Manual parse of files: \(files)")
                    print("📱 AGENT-API - Manual files count: \(files.count)")
                }
                
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Response Models

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
