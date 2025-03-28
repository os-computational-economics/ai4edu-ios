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
    @State private var navigateToContinueChat: Bool = false
    @State private var agentForContinue: Agent? = nil
    @State private var isCurrentUserThread: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with thread info and continue chat button
            HStack {
                // Back button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(thread.agentName)
                        .font(.headline)
                    
                    HStack {
                        Text(formatWorkspaceId(thread.workspaceId))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Continue chat button - only show if created by current user
                if isCurrentUserThread {
                    Button(action: {
                        presentContinueChat()
                    }) {
                        Label("Continue Chat", systemImage: "arrow.right.circle")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            if isLoading {
                Spacer()
                ProgressView("Loading messages...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Error loading messages")
                        .font(.headline)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button("Try Again") {
                        loadMessages()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    if isCurrentUserThread {
                        Divider()
                            .padding(.vertical, 10)
                            .padding(.horizontal, 40)
                        
                        Text("Or continue the chat without loading past messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Continue Chat") {
                            presentContinueChat()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                Spacer()
            } else if messages.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No messages in this thread")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isCurrentUserThread {
                        Text("Continue the chat to start a conversation with this agent")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                        
                        Button("Continue Chat") {
                            presentContinueChat()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        Text("This thread was created by another user and has no messages yet")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
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
            
            // Navigation link for continue chat (hidden)
            NavigationLink(
                destination: Group {
                    if let agent = agentForContinue {
                        AgentDetailView(agent: agent, initialThreadId: thread.threadId)
                            .navigationBarHidden(true)
                    }
                },
                isActive: $navigateToContinueChat
            ) {
                EmptyView()
            }
        }
        .background(Color(UIColor.systemGray6))
        .onAppear {
            loadMessages()
            checkIfCurrentUserThread()
        }
        .navigationBarHidden(true)
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
    
    private func checkIfCurrentUserThread() {
        // Get the current user ID (student ID)
        let currentUserId = ChatService.shared.getCurrentStudentID()
        
        // Convert thread.userId to String for comparison
        let threadUserId = String(thread.userId)
        
        // Check if this thread was created by the current user
        isCurrentUserThread = (threadUserId == currentUserId)
        
        print("📱 THREAD-DETAIL - Thread user ID: \(threadUserId), Current user ID: \(currentUserId)")
        print("📱 THREAD-DETAIL - Is current user's thread: \(isCurrentUserThread)")
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
    
    // Create a separate method to present the ContinueChatView
    private func presentContinueChat() {
        print("📱 THREAD-DETAIL - Continue chat button pressed for thread: \(thread.threadId)")
        
        // Show loading state if needed
        isLoading = true
        
        // Fetch the full agent details from the API
        ChatService.shared.getAgentDetails(agentId: thread.agentId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let agent):
                    print("📱 THREAD-DETAIL - Successfully loaded agent: \(agent.agentName) for thread: \(self.thread.threadId)")
                    // Set the agent and trigger navigation
                    self.agentForContinue = agent
                    
                    // Use a short delay to ensure state is updated
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("📱 THREAD-DETAIL - Navigating to continue chat with thread: \(self.thread.threadId)")
                        self.navigateToContinueChat = true
                    }
                    
                case .failure(let error):
                    print("📱 THREAD-DETAIL - Error loading agent details: \(error)")
                    // Handle error - fallback to using limited information we have
                    let fallbackAgent = Agent(
                        agentId: self.thread.agentId,
                        agentName: self.thread.agentName,
                        workspaceId: self.thread.workspaceId,
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
                    
                    self.agentForContinue = fallbackAgent
                    
                    // Still proceed with navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("📱 THREAD-DETAIL - Navigating to continue chat with thread: \(self.thread.threadId) using fallback agent")
                        self.navigateToContinueChat = true
                    }
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
