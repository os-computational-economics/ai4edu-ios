//
//  AgentDetailView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI
import Combine
import Foundation

struct AgentDetailView: View {
    let agent: Agent
    
    @State private var messages: [ChatMessage] = []
    @State private var messageText: String = ""
    @State private var isLoading: Bool = false
    @State private var showAgentInfo: Bool = true
    @State private var selectedTab: DetailTab = .chat
    @State private var currentThreadId: String? = nil  // Store the thread ID
    @State private var messageUpdateCounter: Int = 0   // Track message content updates
    @StateObject private var streamObserver = StreamingObserver()  // Add streaming observer
    
    enum DetailTab {
        case chat
        case details
        case files
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header with more detailed information
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    // Agent name and status
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center, spacing: 12) {
                            Text(agent.agentName)
                                .font(.title)
                                .fontWeight(.bold)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Status indicator
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(agent.status == 1 ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                
                                Text(agent.status == 1 ? "Active" : "Disabled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(agent.status == 1 ? .green : .red)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(agent.status == 1 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            )
                        }
                        
                        HStack(spacing: 12) {
                            Text("Workspace: \(formatWorkspaceId(agent.workspaceId))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !agent.creator.isEmpty {
                                Divider()
                                    .frame(height: 16)
                                
                                Text("Created by: \(agent.creator)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Tab selector
                HStack(spacing: 0) {
                    TabButton(
                        title: "Chat",
                        systemImage: "bubble.left.and.bubble.right",
                        isSelected: selectedTab == .chat,
                        isEnabled: agent.status == 1,
                        action: { selectedTab = .chat }
                    )
                    
                    TabButton(
                        title: "Details",
                        systemImage: "info.circle",
                        isSelected: selectedTab == .details,
                        action: { selectedTab = .details }
                    )
                    
                    if !agent.agentFiles.isEmpty {
                        TabButton(
                            title: "Files",
                            systemImage: "doc.on.doc",
                            isSelected: selectedTab == .files,
                            action: { selectedTab = .files }
                        )
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .overlay(
                Divider(),
                alignment: .bottom
            )
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                chatView
                    .tag(DetailTab.chat)
                
                agentDetailsView
                    .tag(DetailTab.details)
                
                if !agent.agentFiles.isEmpty {
                    filesView
                        .tag(DetailTab.files)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Agent Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Tab Views
    
    private var chatView: some View {
        Group {
            if agent.status == 1 {
                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if messages.isEmpty {
                                    VStack(spacing: 20) {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray.opacity(0.5))
                                            .padding(.top, 60)
                                        
                                        Text("Start a conversation with \(agent.agentName)")
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal)
                                        
                                        Text("Ask a question to begin chatting with this agent")
                                            .font(.subheadline)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal)
                                        
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                } else {
                                    ForEach(messages) { message in
                                        ChatBubble(message: message, agentName: agent.agentName)
                                            .padding(.horizontal)
                                            .id("\(message.id)-\(message.text.hashValue)") // Add hash to ID for refreshing
                                    }
                                    
                                    if isLoading {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .padding()
                                            Spacer()
                                        }
                                    }
                                    
                                    // Invisible element at the bottom for scrolling
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 1)
                                        .id("bottom")
                                }
                            }
                            .padding(.top)
                        }
                        .onChange(of: messages.count) { _ in
                            withAnimation {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: isLoading) { _ in
                            withAnimation {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: messageUpdateCounter) { _ in
                            withAnimation {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: streamObserver.lastUpdatedId) { _ in
                            // Scroll when streaming updates occur
                            withAnimation {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    
                    // Enhanced input area
                    HStack(spacing: 12) {
                        TextField("Type your message...", text: $messageText)
                            .padding(12)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button(action: sendMessage) {
                            ZStack {
                                Circle()
                                    .fill(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? 
                                          Color.blue.opacity(0.3) : Color.blue)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        Divider(),
                        alignment: .top
                    )
                }
            } else {
                // Agent is disabled
                VStack(spacing: 20) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(.top, 60)
                    
                    Text("Agent is currently disabled")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("This agent is not available for chat. Please try another agent or check back later.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            }
        }
    }
    
    private var agentDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Basic details card
                detailCard(title: "Basic Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(title: "Agent ID", value: agent.agentId)
                        detailRow(title: "Status", value: agent.status == 1 ? "Active" : "Disabled")
                        detailRow(title: "Workspace", value: formatWorkspaceId(agent.workspaceId))
                        if !agent.creator.isEmpty {
                            detailRow(title: "Created By", value: agent.creator)
                        }
                        if !agent.model.isEmpty {
                            detailRow(title: "Model", value: agent.model)
                        }
                    }
                }
                
                // Additional features card
                detailCard(title: "Features") {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(title: "Voice Enabled", value: agent.voice ? "Yes" : "No")
                        detailRow(title: "Allow Model Choice", value: agent.allowModelChoice ? "Yes" : "No")
                    }
                }
                
                // Timestamps card
                detailCard(title: "Timestamps") {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(title: "Created", value: formatDate(agent.createdAt, includeTime: true))
                        detailRow(title: "Last Updated", value: formatDate(agent.updatedAt, includeTime: true))
                    }
                }
                
                // Files card (if any)
                if !agent.agentFiles.isEmpty {
                    detailCard(title: "Attached Files (\(agent.agentFiles.count))") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(agent.agentFiles), id: \.key) { fileId, fileName in
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.blue)
                                    
                                    Text(fileName)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("ID: \(fileId)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                                
                                if fileId != Array(agent.agentFiles).last?.key {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var filesView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(agent.agentFiles), id: \.key) { fileId, fileName in
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fileName)
                                    .font(.headline)
                                
                                Text("File ID: \(fileId)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // File icon based on extension
                            Image(systemName: getFileIcon(for: fileName))
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                                .frame(width: 50, height: 50)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Divider()
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Helper Views
    
    private func detailCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 130, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
    }
    
    private func TabButton(title: String, systemImage: String, isSelected: Bool, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .font(.system(size: 14))
                    
                    Text(title)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Indicator for selected tab
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .foregroundColor(isSelected ? .blue : (isEnabled ? .primary : .gray))
        .disabled(!isEnabled)
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatWorkspaceId(_ id: String) -> String {
        let formattedId = id.replacingOccurrences(of: "_", with: ".")
        return formattedId
    }
    
    private func sendMessage() {
        print("messageTExt: \(messageText)")
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            text: messageText,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Clear input field
        let userMessageText = messageText
        messageText = ""
        
        // Show loading indicator
        isLoading = true
        
        // If we already have a thread ID, use it, otherwise create a new thread
        if let threadId = currentThreadId {
            print("Reusing existing thread: \(threadId)")
            sendMessageToThread(userMessageText, threadId: threadId)
        } else {
            // Create a new thread
            ChatService.shared.createNewThread(
                agentId: agent.agentId,
                workspaceId: agent.workspaceId
            ) { result in
                switch result {
                case .success(let threadId):
                    print("successfully created new thread with id: \(threadId)")
                    // Store the thread ID for future use
                    self.currentThreadId = threadId
                    self.sendMessageToThread(userMessageText, threadId: threadId)
                    
                case .failure(let error):
                    print("Error creating thread: \(error)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        // Show error message
                        let errorMessage = ChatMessage(
                            id: UUID().uuidString,
                            text: "Sorry, there was an error creating a chat thread. Please try again later.",
                            isFromUser: false,
                            timestamp: Date()
                        )
                        self.messages.append(errorMessage)
                    }
                }
            }
        }
    }
    
    private func sendMessageToThread(_ messageText: String, threadId: String) {
        // Convert existing messages to the format required by the API
        var previousMessages: [[String: Any]] = []
        
        // Add all previous messages from the conversation
        for (index, message) in messages.enumerated() {
            let role = message.isFromUser ? "user" : "assistant"
            previousMessages.append([
                "role": role,
                "content": message.text
            ])
        }
        
        // Add the new user message at the end
        previousMessages.append([
            "role": "user",
            "content": messageText
        ])
        
        print("Sending \(previousMessages.count) messages in conversation history")
        
        // Create a placeholder message for streaming updates
        let placeholderId = "placeholder-\(UUID().uuidString)"
        let placeholderMessage = ChatMessage(
            id: placeholderId,
            text: "...",
            isFromUser: false,
            timestamp: Date()
        )
        
        // Reset streaming observer and add placeholder
        streamObserver.reset(placeholderId: placeholderId)
        
        // Add placeholder to UI
        messages.append(placeholderMessage)
        
        // Force UI update
        messageUpdateCounter += 1
        
        // Setup observer for streaming updates
        streamObserver.onUpdate = { [self] newContent in
            if let index = self.messages.firstIndex(where: { $0.id == placeholderId }) {
                // Update directly on main thread
                DispatchQueue.main.async {
                    self.messages[index].text = newContent
                    self.messageUpdateCounter += 1
                    // Print for debugging
                    print("UI UPDATED with: \(newContent.prefix(10))...")
                }
            }
        }
        
        // Use the callback-based streaming method
        ChatService.shared.streamMessageWithCallback(
            message: messageText,
            threadId: threadId,
            agentId: agent.agentId,
            workspaceId: agent.workspaceId,
            previousMessages: previousMessages,
            onChunk: { [self] chunkText in
                // Update via the observer
                self.streamObserver.updateContent(chunkText)
            },
            onCompletion: { [self] result in
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    // Process the final result
                    switch result {
                    case .success(let response):
                        print("Streaming completed with message: \(response.messageId)")
                        
                        // Replace the placeholder with final message
                        if let index = self.messages.firstIndex(where: { $0.id == placeholderId }) {
                            self.messages.remove(at: index)
                            
                            // Add final agent response
                            let agentMessage = ChatMessage(
                                id: UUID().uuidString,
                                text: response.content, 
                                isFromUser: false,
                                timestamp: Date()
                            )
                            self.messages.append(agentMessage)
                            self.messageUpdateCounter += 1
                        }
                        
                    case .failure(let error):
                        print("Error in streaming: \(error)")
                        
                        // Remove placeholder
                        if let index = self.messages.firstIndex(where: { $0.id == placeholderId }) {
                            self.messages.remove(at: index)
                            
                            // Show error message
                            let errorMessage = ChatMessage(
                                id: UUID().uuidString,
                                text: "Sorry, there was an error processing your request. Please try again later.",
                                isFromUser: false,
                                timestamp: Date()
                            )
                            self.messages.append(errorMessage)
                            self.messageUpdateCounter += 1
                        }
                    }
                }
            }
        )
    }
    
    private func formatDate(_ dateString: String, includeTime: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            
            if includeTime {
                displayFormatter.timeStyle = .short
            } else {
                displayFormatter.timeStyle = .none
            }
            
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func getFileIcon(for fileName: String) -> String {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return "doc.text.fill"
        case "doc", "docx":
            return "doc.fill"
        case "xls", "xlsx":
            return "chart.bar.doc.horizontal.fill"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal.fill"
        case "txt":
            return "doc.plaintext.fill"
        case "jpg", "jpeg", "png", "gif":
            return "photo.fill"
        case "mp3", "wav", "aac":
            return "music.note.list"
        case "mp4", "mov", "avi":
            return "play.rectangle.fill"
        case "zip", "rar":
            return "archivebox.fill"
        default:
            return "doc.fill"
        }
    }
}

// MARK: - Chat Components

struct ChatMessage: Identifiable {
    let id: String
    var text: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - Streaming Helper

class StreamingObserver: ObservableObject {
    @Published var content: String = ""
    @Published var lastUpdatedId: String = UUID().uuidString
    var placeholderId: String = ""
    var onUpdate: ((String) -> Void)?
    
    func reset(placeholderId: String) {
        self.content = ""
        self.placeholderId = placeholderId
        self.lastUpdatedId = UUID().uuidString
    }
    
    func updateContent(_ newContent: String) {
        // Update on the main thread
        DispatchQueue.main.async { [self] in
            self.content = newContent
            self.lastUpdatedId = UUID().uuidString
            self.onUpdate?(newContent)
        }
    }
}

// MARK: - Preview

struct AgentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AgentDetailView(agent: Agent.mockAgents[0])
        }
    }
} 
