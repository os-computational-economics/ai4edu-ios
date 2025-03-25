//
//  ChatThreadDetailView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI

struct ChatThreadDetailView: View {
    let thread: ThreadInfo
    
    @State private var messages: [Message] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with thread info
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
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            // Convert Message to ChatMessage format for ChatBubble
                            let chatMessage = ChatMessage(
                                id: message.id,
                                text: message.content,
                                isFromUser: message.align == "end",
                                timestamp: parseDate(message.id) // Use ID to generate timestamp since we don't have one
                            )
                            
                            ChatBubble(message: chatMessage, agentName: thread.agentName)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
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
        // Try to extract a timestamp from the UUID if it contains one
        // Otherwise just use current time
        return Date()
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
