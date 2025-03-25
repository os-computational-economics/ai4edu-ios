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
    
    /// Creates a new thread for a specific agent and workspace
    func createNewThread(agentId: String, workspaceId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "/user/get_new_thread"
        
        // Add query parameters
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = [
            URLQueryItem(name: "agent_id", value: agentId),
            URLQueryItem(name: "workspace_id", value: workspaceId)
        ]
        
        guard let url = urlComponents?.url else {
            print("📱 CHAT-API - Error: Invalid URL constructed")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        print("📱 CHAT-API - Making request to URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authorization header
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
            print("📱 CHAT-API - Added authorization header")
        } else {
            print("📱 CHAT-API - WARNING: No access token available for authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("📱 CHAT-API - Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 CHAT-API - HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("📱 CHAT-API - Error: No data received from server")
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 CHAT-API - Raw Response: \(responseString)")
                }
                
                let response = try JSONDecoder().decode(ThreadResponse.self, from: data)
                print("📱 CHAT-API - Thread created: \(response.data.threadId)")
                completion(.success(response.data.threadId))
            } catch {
                print("📱 CHAT-API - JSON Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Loads messages for a thread
    func getThreadMessages(threadId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        let endpoint = "/thread/get_thread"
        
        // Add query parameters
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = [
            URLQueryItem(name: "thread_id", value: threadId)
        ]
        
        guard let url = urlComponents?.url else {
            print("📱 CHAT-API - Error: Invalid URL constructed")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authorization header
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
            print("📱 CHAT-API - Added authorization header")
        } else {
            print("📱 CHAT-API - WARNING: No access token available for authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("📱 CHAT-API - Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("📱 CHAT-API - Error: No data received")
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ThreadDataResponse.self, from: data)
                
                // Convert API messages to our Message model
                let messages = response.messages.map { apiMessage -> Message in
                    return Message(
                        id: apiMessage.id,
                        content: apiMessage.content,
                        align: apiMessage.role == "human" ? "end" : "start",
                        user_id: apiMessage.userId,
                        MsgId: apiMessage.id
                    )
                }
                
                DispatchQueue.main.async {
                    completion(.success(messages))
                }
            } catch {
                print("📱 CHAT-API - JSON Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Chat Communication
    
    /// Sends a message to a thread and handles streaming response
    func sendMessage(message: String, threadId: String, agentId: String, workspaceId: String, previousMessages: [[String: Any]]? = nil, completion: @escaping (Result<ChatResponse, Error>) -> Void) {
        let endpoint = "/user/stream_chat"
        
        guard let url = URL(string: baseURL + endpoint) else {
            print("📱 CHAT-API - Error: Invalid URL constructed")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        // Get current student ID from our helper method
        let studentId = getCurrentStudentID()
        
        print("📱 CHAT-API - Sending message with studentId: \(studentId)")
        
        // Get agent details from local storage or parameters
        let model = "openai" // Default model if not specified in agent
        let voice = false // Default value
        
        // Create messages dictionary
        var messagesDict = [String: [String: String]]()
        
        // Add previous messages if provided
        if let previousMessages = previousMessages {
            for (index, msgDict) in previousMessages.enumerated() {
                if let role = msgDict["role"] as? String,
                   let content = msgDict["content"] as? String {
                    messagesDict["\(index)"] = ["role": role, "content": content]
                }
            }
        } else {
            // Just add the current message if no history
            messagesDict["0"] = ["role": "user", "content": message]
        }
        
        // Format the message for the API - using dictionary with numerical keys
        let chatMessage = [
            "dynamic_auth_code": "random",
            "messages": messagesDict,
            "thread_id": threadId,
            "workspace_id": workspaceId,
            "provider": model,
            "user_id": studentId,
            "agent_id": agentId,
            "voice": voice
        ] as [String: Any]
        
        print("📱 CHAT-API - Request payload: \(chatMessage)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
            print("📱 CHAT-API - Using access token: \(accessToken.prefix(15))...")
        } else {
            print("📱 CHAT-API - WARNING: No access token available for authorization")
            completion(.failure(APIError.networkError))
            return
        }
        
        // Serialize the request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: chatMessage)
        } catch {
            print("📱 CHAT-API - Error serializing request body: \(error)")
            completion(.failure(error))
            return
        }
        
        print("📱 CHAT-API - Sending message to thread: \(threadId)")
        
        // Create a URLSession data task for the streaming response
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("📱 CHAT-API - Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 CHAT-API - HTTP Status Code: \(httpResponse.statusCode)")
                print("📱 CHAT-API - Response Headers:")
                httpResponse.allHeaderFields.forEach { key, value in
                    print("📱 CHAT-API -   \(key): \(value)")
                }
            }
            
            guard let data = data else {
                print("📱 CHAT-API - Error: No data received")
                DispatchQueue.main.async {
                    completion(.failure(APIError.noData))
                }
                return
            }
            
            print("📱 CHAT-API - Received \(data.count) bytes of data")
            
            // Handle the streamed response
            if let dataString = String(data: data, encoding: .utf8) {
                print("📱 CHAT-API - Raw Response: \(dataString)")
                
                // Split the response by newlines to get each event
                let events = dataString.components(separatedBy: "\n")
                    .filter { !$0.isEmpty && $0.hasPrefix("data: ") }
                
                print("📱 CHAT-API - Found \(events.count) events in response")
                
                // Process the last complete message
                if let lastEvent = events.last?.dropFirst(6) { // Remove "data: " prefix
                    do {
                        print("📱 CHAT-API - Last event: \(lastEvent)")
                        let jsonData = Data(lastEvent.utf8)
                        
                        // Try parsing as a dictionary first
                        if let responseDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                           let responseText = responseDict["response"] as? String {
                            
                            // Get message ID if available
                            let msgId = responseDict["msg_id"] as? String ?? UUID().uuidString
                            
                            // Create sources array if available
                            var sources: [Source]? = nil
                            if let sourceArray = responseDict["source"] as? [[String: Any]], !sourceArray.isEmpty {
                                sources = []
                                for (index, sourceItem) in sourceArray.enumerated() {
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
                            print("📱 CHAT-API - Error parsing response JSON")
                            DispatchQueue.main.async {
                                completion(.failure(APIError.decodingError))
                            }
                        }
                    } catch {
                        print("📱 CHAT-API - Error decoding response: \(error)")
                        if let jsonString = String(data: Data(lastEvent.utf8), encoding: .utf8) {
                            print("📱 CHAT-API - JSON that failed to decode: \(jsonString)")
                        }
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                } else {
                    print("📱 CHAT-API - No valid events found in response")
                    DispatchQueue.main.async {
                        completion(.failure(APIError.noData))
                    }
                }
            } else {
                print("📱 CHAT-API - Could not decode response data as UTF-8")
                DispatchQueue.main.async {
                    completion(.failure(APIError.decodingError))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - AsyncStream version of sendMessage for better streaming support
    func streamMessage(message: String, threadId: String, agentId: String, workspaceId: String, previousMessages: [[String: Any]]? = nil) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let endpoint = "/user/stream_chat"
            
            guard let url = URL(string: baseURL + endpoint) else {
                print("📱 CHAT-API - Error: Invalid URL constructed")
                continuation.finish(throwing: APIError.invalidURL)
                return
            }
            
            // Get current student ID from our helper method
            let studentId = getCurrentStudentID()
            
            print("📱 CHAT-API - [Stream] Starting API request")
            print("📱 CHAT-API - [Stream] URL: \(baseURL + endpoint)")
            print("📱 CHAT-API - [Stream] Student ID: \(studentId)")
            print("📱 CHAT-API - [Stream] Thread ID: \(threadId)")
            print("📱 CHAT-API - [Stream] Agent ID: \(agentId)")
            print("📱 CHAT-API - [Stream] Workspace ID: \(workspaceId)")
            print("📱 CHAT-API - [Stream] Message: \"\(message)\"")
            
            // Create messages dictionary
            var messagesDict = [String: [String: String]]()
            
            // Add previous messages if provided
            if let previousMessages = previousMessages {
                for (index, msgDict) in previousMessages.enumerated() {
                    if let role = msgDict["role"] as? String,
                       let content = msgDict["content"] as? String {
                        messagesDict["\(index)"] = ["role": role, "content": content]
                    }
                }
            } else {
                // Just add the current message if no history
                messagesDict["0"] = ["role": "user", "content": message]
            }
            
            // Format the message for the API - using dictionary with numerical keys
            let chatMessage = [
                "dynamic_auth_code": "random",
                "messages": messagesDict,
                "thread_id": threadId,
                "workspace_id": workspaceId,
                "provider": "openai",
                "user_id": studentId,
                "agent_id": agentId,
                "voice": false
            ] as [String: Any]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Add authorization header
            if let accessToken = getAccessToken() {
                request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
                print("📱 CHAT-API - [Stream] Using access token: \(accessToken.prefix(15))...")
            } else {
                print("📱 CHAT-API - [Stream] WARNING: No access token available for authorization")
                continuation.finish(throwing: APIError.networkError)
                return
            }
            
            // Serialize the request body
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: chatMessage)
                request.httpBody = jsonData
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📱 CHAT-API - [Stream] Request payload: \(jsonString)")
                }
            } catch {
                print("📱 CHAT-API - [Stream] Error serializing request body: \(error)")
                continuation.finish(throwing: error)
                return
            }
            
            print("📱 CHAT-API - [Stream] Sending request to server...")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("📱 CHAT-API - [Stream] Network error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📱 CHAT-API - [Stream] HTTP Status Code: \(httpResponse.statusCode)")
                    print("📱 CHAT-API - [Stream] Response Headers:")
                    httpResponse.allHeaderFields.forEach { key, value in
                        print("📱 CHAT-API - [Stream]   \(key): \(value)")
                    }
                }
                
                guard let data = data else {
                    print("📱 CHAT-API - [Stream] Error: No data received")
                    continuation.finish(throwing: APIError.noData)
                    return
                }
                
                print("📱 CHAT-API - [Stream] Received \(data.count) bytes of data")
                
                // Handle the streamed response
                if let dataString = String(data: data, encoding: .utf8) {
                    print("📱 CHAT-API - [Stream] Raw Response: \(dataString)")
                    
                    // Split the response by newlines to get each event
                    let events = dataString.components(separatedBy: "\n")
                        .filter { !$0.isEmpty && $0.hasPrefix("data: ") }
                    
                    print("📱 CHAT-API - [Stream] Processing \(events.count) events")
                    
                    var lastResponse = ""
                    var messageId = ""
                    var eventCounter = 0
                    
                    for eventString in events {
                        eventCounter += 1
                        let event = eventString.dropFirst(6) // Remove "data: " prefix
                        
                        print("📱 CHAT-API - [Stream] Processing event #\(eventCounter): \(event)")
                        
                        do {
                            let jsonData = Data(event.utf8)
                            // Try to decode with the updated MessageResponse struct
                            if let responseDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                               let responseText = responseDict["response"] as? String {
                                
                                lastResponse = responseText
                                if let msgId = responseDict["msg_id"] as? String {
                                    messageId = msgId
                                }
                                
                                print("📱 CHAT-API - [Stream] Event #\(eventCounter) response: \"\(lastResponse.prefix(100))...\"")
                                
                                // Yield the response text for the UI to update
                                continuation.yield(lastResponse)
                            } else {
                                print("📱 CHAT-API - [Stream] Event #\(eventCounter) could not be parsed as JSON")
                                if let jsonString = String(data: jsonData, encoding: .utf8) {
                                    print("📱 CHAT-API - [Stream] Raw JSON: \(jsonString)")
                                }
                            }
                        } catch {
                            print("📱 CHAT-API - [Stream] Error parsing event: \(error)")
                        }
                    }
                    
                    if !lastResponse.isEmpty {
                        print("📱 CHAT-API - [Stream] Stream completed successfully")
                        print("📱 CHAT-API - [Stream] Final message ID: \(messageId)")
                        print("📱 CHAT-API - [Stream] Total events processed: \(eventCounter)")
                        print("📱 CHAT-API - [Stream] Final response length: \(lastResponse.count) characters")
                        continuation.finish()
                    } else {
                        print("📱 CHAT-API - [Stream] No valid content found in any events")
                        continuation.finish(throwing: APIError.decodingError)
                    }
                } else {
                    print("📱 CHAT-API - [Stream] Could not decode response data as UTF-8")
                    continuation.finish(throwing: APIError.decodingError)
                }
            }
            
            task.resume()
        }
    }
    
    // Process the stream directly with callbacks for real-time updates
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
            print("📱 CHAT-API - Error: Invalid URL constructed")
            onCompletion(.failure(APIError.invalidURL))
            return
        }
        
        // Get current student ID from our helper method
        let studentId = getCurrentStudentID()
        
        print("📱 CHAT-API - [StreamCallback] Starting API request")
        print("📱 CHAT-API - [StreamCallback] URL: \(baseURL + endpoint)")
        print("📱 CHAT-API - [StreamCallback] Student ID: \(studentId)")
        print("📱 CHAT-API - [StreamCallback] Thread ID: \(threadId)")
        
        // Create messages dictionary
        var messagesDict = [String: [String: String]]()
        
        // Add previous messages if provided
        if let previousMessages = previousMessages {
            for (index, msgDict) in previousMessages.enumerated() {
                if let role = msgDict["role"] as? String,
                   let content = msgDict["content"] as? String {
                    messagesDict["\(index)"] = ["role": role, "content": content]
                }
            }
        } else {
            // Just add the current message if no history
            messagesDict["0"] = ["role": "user", "content": message]
        }
        
        // Format the message for the API
        let chatMessage = [
            "dynamic_auth_code": "random",
            "messages": messagesDict,
            "thread_id": threadId,
            "workspace_id": workspaceId,
            "provider": "openai",
            "user_id": studentId,
            "agent_id": agentId,
            "voice": false
        ] as [String: Any]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
            print("📱 CHAT-API - [StreamCallback] Using access token: \(accessToken.prefix(15))...")
        } else {
            print("📱 CHAT-API - [StreamCallback] WARNING: No access token available for authorization")
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
            print("📱 CHAT-API - [StreamCallback] Error serializing request body: \(error)")
            onCompletion(.failure(error))
            return
        }
        
        print("📱 CHAT-API - [StreamCallback] Sending request to server...")
        
        // Create a stream delegate to process data incrementally
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
            // Append new data to buffer
            buffer.append(data)
            
            // Check for complete lines
            if let dataString = String(data: buffer, encoding: .utf8) {
                let lines = dataString.components(separatedBy: "\n")
                
                // Process complete events (data: {...})
                for line in lines where line.hasPrefix("data: ") {
                    eventCount += 1
                    let event = line.dropFirst(6) // Remove "data: " prefix
                    
                    do {
                        if let data = event.data(using: .utf8),
                           let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            
                            // Extract message ID if available
                            if let msgId = responseDict["msg_id"] as? String {
                                messageId = msgId
                            }
                            
                            // Extract response text and notify
                            if let text = responseDict["response"] as? String {
                                // Only log occasionally to reduce console spam
                                if eventCount % 100 == 0 || eventCount < 10 {
                                    print("📱 CHAT-API - [Stream] Event #\(eventCount): \"\(text.prefix(30))...\"")
                                }
                                
                                // Calculate the new content that was added
                                if text.count > previousLength {
                                    // Only send the new part to the UI
                                    let newContent = String(text.dropFirst(previousLength))
                                    if !newContent.isEmpty {
                                        responseText = text
                                        onChunk(text) // Send complete text to ensure consistency
                                        previousLength = text.count
                                    }
                                }
                            }
                            
                            // Extract sources if available
                            if let sourceArray = responseDict["source"] as? [[String: Any]], !sourceArray.isEmpty {
                                sources = []
                                for (index, sourceItem) in sourceArray.enumerated() {
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
                
                // If the last line is complete, clear the buffer
                if dataString.hasSuffix("\n") {
                    buffer = Data()
                } else if let lastNewlineRange = dataString.range(of: "\n", options: .backwards) {
                    // Keep partial line in buffer
                    let partialLine = dataString[lastNewlineRange.upperBound...]
                    if let partialData = String(partialLine).data(using: .utf8) {
                        buffer = partialData
                    }
                }
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error {
                print("📱 CHAT-API - [Stream] Network error: \(error.localizedDescription)")
                onCompletion(.failure(error))
                return
            }
            
            print("📱 CHAT-API - [Stream] Stream completed successfully")
            print("📱 CHAT-API - [Stream] Final message ID: \(messageId)")
            print("📱 CHAT-API - [Stream] Total events processed: \(eventCount)")
            
            if !responseText.isEmpty {
                // Create final response object
                let chatResponse = ChatResponse(
                    threadId: threadId,
                    messageId: messageId.isEmpty ? UUID().uuidString : messageId,
                    content: responseText,
                    sources: sources
                )
                
                onCompletion(.success(chatResponse))
            } else {
                print("📱 CHAT-API - [Stream] No valid content found in any events")
                onCompletion(.failure(APIError.decodingError))
            }
        }
    }
    
    // MARK: - Feedback
    
    /// Submits a rating for a message
    func submitRating(threadId: String, messageId: String, rating: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        let endpoint = "/feedback/feedback"
        
        guard let url = URL(string: baseURL + endpoint) else {
            print("📱 CHAT-API - Error: Invalid URL constructed")
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
        
        // Add authorization header
        if let accessToken = getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("📱 CHAT-API - WARNING: No access token available for authorization")
        }
        
        // Serialize the request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: feedback)
        } catch {
            print("📱 CHAT-API - Error serializing feedback: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("📱 CHAT-API - Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    /// Get the current user's student ID
    private func getCurrentStudentID() -> String {
        // Try to get from UserDefaults
        if let studentId = UserDefaults.standard.string(forKey: "studentId"),
           !studentId.isEmpty && studentId != "unknown" {
            return studentId
        }
        
        // Fallback to Cookies if implemented
        if let cookiesValue = UserDefaults.standard.string(forKey: "cookies") {
            if cookiesValue.contains("student_id=") {
                let components = cookiesValue.components(separatedBy: "student_id=")
                if components.count > 1 {
                    let idWithRemainder = components[1]
                    if let endIndex = idWithRemainder.firstIndex(of: ";") {
                        return String(idWithRemainder[..<endIndex])
                    }
                    return idWithRemainder
                }
            }
        }
        
        // Default to "7" for testing to match expected format, instead of "unknown"
        return "7"
    }
    
    /// Get access token
    private func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: "accessToken") ?? TokenManager.shared.getAccessToken()
    }
}

// MARK: - Response Models

/// Response for thread creation
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

/// Response for thread messages
struct ThreadDataResponse: Codable {
    let messages: [APIMessage]
    
    struct APIMessage: Codable {
        let id: String
        let content: String
        let role: String
        let userId: String?
        
        enum CodingKeys: String, CodingKey {
            case id, content, role
            case userId = "user_id"
        }
    }
}

// End of file
