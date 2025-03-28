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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with more detailed information - matching AgentDetailView style
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    // Back button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(6)
                            .background(Color(.systemGray5).opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 8)
                    
                    // Agent name and thread info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center, spacing: 12) {
                            Text(thread.agentName)
                                .font(.title)
                                .fontWeight(.bold)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Text("Thread: \(thread.threadId.prefix(8))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Continue chat button
                    Button(action: {
                        presentContinueChat()
                    }) {
                        Label("Continue", systemImage: "arrow.right.circle")
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
            .overlay(
                Divider(),
                alignment: .bottom
            )
            
            // Content
            if isLoading {
                Spacer()
                ProgressView("Loading messages...")
                    .padding(.top, 40)
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Error loading messages")
                        .font(.headline)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        loadMessages()
                    }) {
                        Text("Try Again")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
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
                    
                    Text("Continue the chat to start a conversation with this agent")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        presentContinueChat()
                    }) {
                        Text("Continue Chat")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
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
        .edgesIgnoringSafeArea(.bottom)
        .background(Color(UIColor.systemGray6))
        .onAppear {
            loadMessages()
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
        
        // Create a dummy agent for display purposes
        let dummyAgent = Agent(
            agentId: thread.agentId,
            agentName: thread.agentName,
            workspaceId: thread.workspaceId,
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
        
        // First dismiss this view
        presentationMode.wrappedValue.dismiss()
        
        // Then post notification to show agent detail with thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("📱 THREAD-DETAIL - Posting notification to continue chat with thread: \(self.thread.threadId)")
            
            // Post notification for MainTabView to switch to the agent tab
            NotificationCenter.default.post(
                name: NSNotification.Name("SwitchToAgentTab"),
                object: nil,
                userInfo: [
                    "agent": dummyAgent,
                    "threadId": self.thread.threadId
                ]
            )
        }
    }
}

// MARK: - Continue Chat View

struct ContinueChatView: View {
    let agentId: String
    let threadId: String
    let agentName: String
    
    @State private var messages: [Message] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        // This view will now be unused since we're going directly to AgentDetailView
        // Keep minimal implementation for backward compatibility
        AgentDetailView(
            agent: Agent(
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
            ),
            initialThreadId: threadId
        )
    }
    
    private func loadThreadMessages() {
        // Not used anymore
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
