//
//  AgentDetailView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI
import Combine
import Foundation
import UIKit

struct KeyboardToolbar: UIViewRepresentable {
    let doneAction: () -> Void
    
    func makeUIView(context: Context) -> UIToolbar {
        let toolbar = UIToolbar(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        
        toolbar.items = [flexSpace, doneButton]
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    func updateUIView(_ uiView: UIToolbar, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: KeyboardToolbar
        
        init(_ parent: KeyboardToolbar) {
            self.parent = parent
        }
        
        @objc func doneButtonTapped() {
            parent.doneAction()
        }
    }
}

// MARK: - Keyboard Avoiding Modifier
struct KeyboardAvoiding: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .animation(.easeOut(duration: 0.16), value: keyboardHeight)
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                    
                    withAnimation(.easeOut(duration: animationDuration)) {
                        self.keyboardHeight = keyboardFrame.height
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { notification in
                    let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                    
                    withAnimation(.easeOut(duration: animationDuration)) {
                        self.keyboardHeight = 0
                    }
                }
            }
    }
}

extension View {
    func avoidKeyboard() -> some View {
        self.modifier(KeyboardAvoiding())
    }
}

struct AgentDetailView: View {
    let agent: Agent
    var initialThreadId: String? = nil
    var fullScreenMode: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState
    
    @State private var messages: [ChatMessage] = []
    @State private var messageText: String = ""
    @State private var isLoading: Bool = false
    @State private var showAgentInfo: Bool = true
    @State private var selectedTab: DetailTab = .chat
    @State private var currentThreadId: String? = nil
    @State private var messageUpdateCounter: Int = 0
    @StateObject private var streamObserver = StreamingObserver()
    @State private var hasInitialized: Bool = false
    
    enum DetailTab {
        case chat
        case details
        case files
    }
    
    var isStudent: Bool {
        appState.currentWorkspace?.role.lowercased() == "student"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center, spacing: 12) {
                            Text(agent.agentName)
                                .font(.title)
                                .fontWeight(.bold)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
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
                            Text("Workspace: \(agent.workspaceId)")
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
                
                if !fullScreenMode {
                    HStack(spacing: 0) {
                        TabButton(
                            title: "Chat",
                            systemImage: "bubble.left.and.bubble.right",
                            isSelected: selectedTab == .chat,
                            isEnabled: agent.status == 1,
                            action: { selectedTab = .chat }
                        )
                        
                        if !isStudent {
                            TabButton(
                                title: "Details",
                                systemImage: "info.circle",
                                isSelected: selectedTab == .details,
                                action: { selectedTab = .details }
                            )
                        }
                        
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
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .overlay(
                Divider(),
                alignment: .bottom
            )
            
            // In full screen mode, always show chat view
            if fullScreenMode {
                chatView
            } else {
                TabView(selection: $selectedTab) {
                    chatView
                        .tag(DetailTab.chat)
                    
                    if !isStudent {
                        agentDetailsView
                            .tag(DetailTab.details)
                        
                        if !agent.agentFiles.isEmpty {
                            filesView
                                .tag(DetailTab.files)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle(fullScreenMode ? "" : "Agent Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if fullScreenMode {
                NotificationCenter.default.post(name: NSNotification.Name("HideTabBar"), object: nil)
                
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
            if !hasInitialized {
                hasInitialized = true
                
                if let threadId = initialThreadId {
                    currentThreadId = threadId
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        loadThreadMessages(threadId: threadId)
                    }
                } else {
                    print("📱 AGENT-DETAIL - No initial thread ID, starting fresh conversation")
                }
            }
        }
        .onDisappear {
            if fullScreenMode {
                NotificationCenter.default.post(name: NSNotification.Name("ShowTabBar"), object: nil)
                
                // Reset navigation bar appearance
                let standardAppearance = UINavigationBarAppearance()
                standardAppearance.configureWithDefaultBackground()
                UINavigationBar.appearance().standardAppearance = standardAppearance
                UINavigationBar.appearance().compactAppearance = standardAppearance
                UINavigationBar.appearance().scrollEdgeAppearance = standardAppearance
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .statusBar(hidden: fullScreenMode)
    }
    
    // MARK: - Tab Views
    
    private var chatView: some View {
        Group {
            if agent.status == 1 {
                VStack(spacing: 0) {
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if isLoading && messages.isEmpty {
                                    VStack {
                                        ProgressView("Loading messages...")
                                            .padding(.top, 40)
                                    }
                                    .frame(maxWidth: .infinity)
                                } else if messages.isEmpty {
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
                                            .id("\(message.id)-\(message.text.hashValue)")
                                    }
                                    
                                    if isLoading {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .padding()
                                            Spacer()
                                        }
                                    }
                                    
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 1)
                                        .id("bottom")
                                }
                            }
                            .padding(.top)
                        }
                        .simultaneousGesture(
                            DragGesture().onChanged { _ in
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                              to: nil, 
                                                              from: nil, 
                                                              for: nil)
                            }
                        )
                        .gesture(
                            TapGesture()
                                .onEnded { _ in
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                                 to: nil, 
                                                                 from: nil, 
                                                                 for: nil)
                                }
                        )
                        .onChange(of: messages.count) {
                            withAnimation {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: isLoading) {
                            withAnimation {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: messageUpdateCounter) {
                            withAnimation {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: streamObserver.lastUpdatedId) {
                            withAnimation {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: messageText) {
                            if !messages.isEmpty {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        scrollProxy.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Enhanced input area
                    HStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                            // Placeholder text
                            if messageText.isEmpty {
                                Text("Type your message...")
                                    .foregroundColor(Color.gray.opacity(0.8))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            
                            TextEditor(text: $messageText)
                                .padding(.horizontal, 1)
                                .frame(minHeight: 20, maxHeight: 120)
                                .cornerRadius(20)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(messageText.isEmpty ? 0.7 : 1)
                                .background(
                                    KeyboardToolbar {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                                      to: nil, 
                                                                      from: nil, 
                                                                      for: nil)
                                    }
                                    .frame(width: 0, height: 0)
                                )
                        }
                        .padding(8)
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
                    .padding([.horizontal, .bottom], 16)
                    .padding(.top, 8)
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        Divider(),
                        alignment: .top
                    )
                }
                .avoidKeyboard()
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
                detailCard(title: "Basic Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(title: "Agent ID", value: agent.agentId)
                        detailRow(title: "Status", value: agent.status == 1 ? "Active" : "Disabled")
                        detailRow(title: "Workspace", value: agent.workspaceId)
                        if !agent.creator.isEmpty {
                            detailRow(title: "Created By", value: agent.creator)
                        }
                        if !agent.model.isEmpty {
                            detailRow(title: "Model", value: agent.model)
                        }
                    }
                }
                
                detailCard(title: "Features") {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(title: "Voice Enabled", value: agent.voice ? "Yes" : "No")
                        detailRow(title: "Allow Model Choice", value: agent.allowModelChoice ? "Yes" : "No")
                    }
                }
                
                detailCard(title: "Timestamps") {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(title: "Created", value: formatDate(agent.createdAt, includeTime: true))
                        detailRow(title: "Last Updated", value: formatDate(agent.updatedAt, includeTime: true))
                    }
                }
                
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
                        
//                        Divider()
//                            .padding(.top, 8)
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
    
    private func sendMessage() {
        print("messageTExt: \(messageText)")
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            text: messageText,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        let userMessageText = messageText
        messageText = ""
        
        isLoading = true
        
        // If we already have a thread ID, use it, otherwise create a new thread
        if let threadId = currentThreadId {
            print("Reusing existing thread: \(threadId)")
            sendMessageToThread(userMessageText, threadId: threadId)
        } else {
            ChatService.shared.createNewThread(
                agentId: agent.agentId,
                workspaceId: agent.workspaceId
            ) { result in
                switch result {
                case .success(let threadId):
                    print("successfully created new thread with id: \(threadId)")
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
        
        var previousMessages: [[String: Any]] = []
        
        if messages.isEmpty {
            _ = "ai4edu-api.jerryang.org/v1/prod/admin/threads/get_thread/\(threadId)"
        }
        
        for (_, message) in messages.enumerated() {
            let role = message.isFromUser ? "user" : "assistant"
            previousMessages.append([
                "role": role,
                "content": message.text
            ])
        }
        
        previousMessages.append([
            "role": "user",
            "content": messageText
        ])
        
        let placeholderId = "placeholder-\(UUID().uuidString)"
        let placeholderMessage = ChatMessage(
            id: placeholderId,
            text: "...",
            isFromUser: false,
            timestamp: Date()
        )
        
        streamObserver.reset(placeholderId: placeholderId)
        
        messages.append(placeholderMessage)
        
        messageUpdateCounter += 1
        
        streamObserver.onUpdate = { [self] newContent in
            if let index = self.messages.firstIndex(where: { $0.id == placeholderId }) {
                DispatchQueue.main.async {
                    self.messages[index].text = newContent
                    self.messageUpdateCounter += 1
                }
            }
        }
        
        ChatService.shared.streamMessageWithCallback(
            message: messageText,
            threadId: threadId,
            agentId: agent.agentId,
            workspaceId: agent.workspaceId,
            previousMessages: previousMessages,
            onChunk: { [self] chunkText in
                self.streamObserver.updateContent(chunkText)
            },
            onCompletion: { [self] result in
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        if let index = self.messages.firstIndex(where: { $0.id == placeholderId }) {
                            self.messages.remove(at: index)
                            
                            let agentMessage = ChatMessage(
                                id: UUID().uuidString,
                                text: response.content, 
                                isFromUser: false,
                                timestamp: Date()
                            )
                            self.messages.append(agentMessage)
                            self.messageUpdateCounter += 1
                        }
                        
                    case .failure(_):
                        
                        if let index = self.messages.firstIndex(where: { $0.id == placeholderId }) {
                            self.messages.remove(at: index)
                            
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
    
    private func loadThreadMessages(threadId: String) {
        isLoading = true
        
        messages = []
        
        currentThreadId = threadId
        
        _ = "ai4edu-api.jerryang.org/v1/prod/admin/threads/get_thread/\(threadId)"
        
        ChatService.shared.getThreadMessages(threadId: threadId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let apiMessages):
                    if apiMessages.isEmpty {
                        let infoMessage = ChatMessage(
                            id: UUID().uuidString,
                            text: "This conversation has been started but doesn't have any messages yet. You can start typing below.",
                            isFromUser: false,
                            timestamp: Date()
                        )
                        self.messages = [infoMessage]
                        self.messageUpdateCounter += 1
                        return
                    }
                    
                    let chatMessages = apiMessages.map { message -> ChatMessage in
                        let isFromUser = message.role == "human" || (message.role == nil && message.align == "end")
                        let timestamp = self.parseTimestamp(from: message.id)
                        
                        return ChatMessage(
                            id: message.id,
                            text: message.content,
                            isFromUser: isFromUser,
                            timestamp: timestamp
                        )
                    }
                    
                    self.messages = chatMessages
                    self.messageUpdateCounter += 1
                    
                case .failure(let error):
                    
                    let errorMessage = ChatMessage(
                        id: UUID().uuidString,
                        text: "Failed to load previous messages: \(error.localizedDescription). You can still continue the conversation.",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    self.messages = [errorMessage]
                    self.messageUpdateCounter += 1
                }
            }
        }
    }
    
    private func parseTimestamp(from messageId: String) -> Date {
        if messageId.contains("#"), 
           let timestampString = messageId.components(separatedBy: "#").last,
           let timestamp = Double(timestampString) {
            return Date(timeIntervalSince1970: timestamp / 1000.0)
        }
        return Date()
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
        DispatchQueue.main.async { [self] in
            self.content = newContent
            self.lastUpdatedId = UUID().uuidString
            self.onUpdate?(newContent)
        }
    }
}
