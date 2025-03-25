//
//  ChatThreadDetailView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI

struct ChatThreadDetailView: View {
    let thread: ThreadInfo
    
    @Environment(\.presentationMode) var presentationMode
    @State private var messages: [Message] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with thread info and continue chat button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(thread.agentName)
                        .font(.headline)
                    
                    HStack {
                        Text(formatDate(thread.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(formatWorkspaceId(thread.workspaceId))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Use a simple NavigationLink to a separate view
                NavigationLink(
                    destination: ContinueChatView(agentId: thread.agentId, threadId: thread.threadId, agentName: thread.agentName)
                ) {
                    HStack {
                        Image(systemName: "bubble.right.fill")
                        Text("Continue Chat")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .overlay(
                Divider(),
                alignment: .bottom
            )
            
            if isLoading {
                Spacer()
                ProgressView("Loading conversation...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Error loading conversation")
                        .font(.headline)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button("Try Again") {
                        loadMessages()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                Spacer()
            } else if messages.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No messages found")
                        .font(.headline)
                    
                    Text("This conversation appears to be empty.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
                .padding()
                Spacer()
            } else {
                // Message list
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                // Convert Message to ChatMessage format for ChatBubble
                                let chatMessage = ChatMessage(
                                    id: message.id,
                                    text: message.content,
                                    isFromUser: message.align == "end",
                                    timestamp: parseDate(message.id)
                                )
                                
                                ChatBubble(message: chatMessage, agentName: thread.agentName)
                                    .padding(.horizontal)
                                    .id(message.id)
                            }
                            
                            // Invisible element at the bottom for scrolling
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.vertical)
                        .onAppear {
                            // Scroll to bottom when messages load
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    scrollProxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Thread Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        isLoading = true
        errorMessage = nil
        
        // Use the get_thread endpoint with thread ID as shown in the example
        ChatService.shared.getThreadMessages(threadId: thread.threadId) { result in
            self.isLoading = false
            
            switch result {
            case .success(let messages):
                self.messages = messages
                
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                print("Error loading thread messages: \(error)")
            }
        }
    }
    
    // Helper functions for formatting
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func formatWorkspaceId(_ id: String) -> String {
        return id.replacingOccurrences(of: "_", with: ".")
    }
    
    // Generate a timestamp from message ID (fallback method)
    private func parseDate(_ id: String) -> Date {
        // Extract timestamp if in format like "4963b0c8#1742878487244"
        if id.contains("#"), let timeString = id.components(separatedBy: "#").last, 
           let timeInterval = Double(timeString) {
            return Date(timeIntervalSince1970: timeInterval / 1000.0)
        }
        
        // Fallback to current time if date parsing fails
        return Date()
    }
}

// MARK: - Continue Chat View

struct ContinueChatView: View {
    let agentId: String
    let threadId: String
    let agentName: String
    
    @State private var isLoading = true
    @State private var messages: [Message] = []
    @State private var errorMessage: String? = nil
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading conversation...")
                    .onAppear {
                        print("⭐️ ContinueChatView - Loading thread messages with ID: \(threadId)")
                        loadThreadMessages()
                    }
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Error Loading Conversation")
                        .font(.headline)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button("Try Again") {
                        isLoading = true
                        errorMessage = nil
                        loadThreadMessages()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            } else {
                // Create a dummy agent for display purposes
                let dummyAgent = Agent(
                    agentId: agentId,
                    agentName: agentName,
                    workspaceId: "",
                    voice: false,
                    allowModelChoice: false,
                    model: "",
                    agentFiles: [:],
                    status: 1,
                    createdAt: "",
                    creator: "",
                    updatedAt: "",
                    systemPrompt: ""
                )
                
                // Navigate to the chat view with the loaded messages
                AgentDetailView(agent: dummyAgent, initialThreadId: threadId)
                    .onAppear {
                        print("⭐️ ContinueChatView - Navigating to chat with \(messages.count) messages")
                    }
            }
        }
    }
    
    private func loadThreadMessages() {
        ChatService.shared.getThreadMessages(threadId: threadId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let messages):
                    print("⭐️ ContinueChatView - Successfully loaded \(messages.count) messages")
                    self.messages = messages
                    
                case .failure(let error):
                    print("⭐️ ContinueChatView - Error loading messages: \(error)")
                    self.errorMessage = "Failed to load messages: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Preview

struct ChatThreadDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatThreadDetailView(
                thread: ThreadInfo(
                    threadId: "thread-123",
                    createdAt: "2023-03-25 10:30:00.000000",
                    agentId: "agent-456", 
                    userId: 7,
                    workspaceId: "csds_392",
                    agentName: "Math Tutor"
                )
            )
        }
    }
}
