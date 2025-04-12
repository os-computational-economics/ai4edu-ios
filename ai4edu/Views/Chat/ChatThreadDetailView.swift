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
            HStack {
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
                        Text(thread.workspaceId)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
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
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
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
                            
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.vertical)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    scrollProxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            
            NavigationLink(
                destination: Group {
                    if let agent = agentForContinue {
                        AgentDetailView(agent: agent, initialThreadId: thread.threadId)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Color.clear.frame(width: 0, height: 0)
            }
        }
    }
    
    private func loadMessages() {
        isLoading = true
        errorMessage = nil
        
        ChatService.shared.getThreadMessages(threadId: thread.threadId) { result in
            self.isLoading = false
            
            switch result {
            case .success(let messages):
                self.messages = messages
                
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func checkIfCurrentUserThread() {
        let currentUserId = ChatService.shared.getCurrentUserID()
        
        let threadUserId = String(thread.userId)
        
        isCurrentUserThread = (threadUserId == currentUserId)
    }
    
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

    
    private func parseDate(_ id: String) -> Date {
        if id.contains("#"), let timeString = id.components(separatedBy: "#").last,
           let timeInterval = Double(timeString) {
            return Date(timeIntervalSince1970: timeInterval / 1000.0)
        }
        
        return Date()
    }
    
    private func presentContinueChat() {
        
        isLoading = true
        
        ChatService.shared.getAgentDetails(agentId: thread.agentId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let agent):
                    self.agentForContinue = agent
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.navigateToContinueChat = true
                    }
                    
                case .failure(_):
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
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.navigateToContinueChat = true
                    }
                }
            }
        }
    }
}
