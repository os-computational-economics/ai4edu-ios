//
//  ChatHistoryView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI
import Foundation

struct ThreadHistoryView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var threads: [ThreadInfo] = []
    @State private var selectedThread: ThreadInfo? = nil
    @State private var navigateToThreadDetail: Bool = false
    @State private var currentPage: Int = 1
    @State private var pageSize: Int = 20
    @State private var totalThreads: Int = 0
    @State private var isLoading: Bool = false
    @State private var isLoadingMore: Bool = false
    @State private var hasMorePages: Bool = true
    @State private var errorMessage: String? = nil
    @State private var showDebugAlert: Bool = false
    @State private var debugMessage: String = ""
    @State private var currentWorkspaceId: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Thread list content
                if isLoading && threads.isEmpty {
                    // Loading state
                    Spacer()
                    ProgressView("Loading chat history...")
                    Spacer()
                } else if let error = errorMessage, threads.isEmpty {
                    // Error state
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Could not load chat history")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            refreshThreads()
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
                } else if threads.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No Chat History")
                            .font(.headline)
                        
                        Text("Start a conversation with an agent to see your chat history here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    Spacer()
                } else {
                    // Thread list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(threads) { thread in
                                ThreadListItem(thread: thread)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        print("Selected thread: \(thread.threadId)")
                                        selectedThread = thread
                                        navigateToThreadDetail = true
                                    }
                                
                                Divider()
                                    .padding(.leading)
                            }
                            
                            // Load more trigger
                            loadMoreTrigger
                        }
                    }
                    .refreshable {
                        await refreshThreadsAsync()
                    }
                }
                
                // Navigate to thread detail
                NavigationLink(
                    destination: Group {
                        if let thread = selectedThread {
                            ChatThreadDetailView(thread: thread)
                                .navigationBarHidden(true)
                        }
                    },
                    isActive: $navigateToThreadDetail
                ) {
                    EmptyView()
                }
            }
            .navigationBarTitle("Chat History", displayMode: .inline)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadThreadsIfNeeded()
        }
        .onChange(of: appState.currentWorkspace?.id) { newId in
            // Reload threads when workspace changes
            if let newWorkspaceId = newId, newWorkspaceId != currentWorkspaceId {
                currentWorkspaceId = newWorkspaceId
                refreshThreads()
            }
        }
        .alert(isPresented: $showDebugAlert) {
            Alert(
                title: Text("Debug Info"),
                message: Text(debugMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // Load more trigger view
    private var loadMoreTrigger: some View {
        Group {
            if isLoadingMore {
                ProgressView()
                    .padding()
            } else if hasMorePages {
                // Invisible rectangle that triggers loading more when it appears
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(height: 50)
                    .onAppear {
                        loadMoreThreads()
                    }
            } else {
                // End of history message
                Text("End of chat history")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    // Helper functions
    
    private func loadThreadsIfNeeded() {
        // If we don't have threads yet, or workspace has changed, load them
        if threads.isEmpty || 
           (appState.currentWorkspace != nil && currentWorkspaceId != appState.currentWorkspace!.id) {
            if let workspaceId = appState.currentWorkspace?.id {
                currentWorkspaceId = workspaceId
                refreshThreads()
            }
        }
    }
    
    private func refreshThreads() {
        print("📱 THREAD-HISTORY - Refreshing threads")
        // Reset pagination
        currentPage = 1
        isLoading = true
        errorMessage = nil
        
        loadThreads(isRefresh: true)
    }
    
    private func loadMoreIfNeeded() {
        if !isLoadingMore && hasMorePages {
            loadMoreThreads()
        }
    }
    
    private func loadMoreThreads() {
        // Only load more if we have more pages and aren't already loading
        if hasMorePages && !isLoading && !isLoadingMore {
            currentPage += 1
            loadThreads()
        }
    }
    
    private func loadThreads(isRefresh: Bool = false) {
        guard let workspace = appState.currentWorkspace else {
            errorMessage = "No workspace selected"
            isLoading = false
            return
        }
        
        if isRefresh {
            threads = []
            hasMorePages = true
        }
        
        print("📱 THREAD-HISTORY - Loading threads for page \(currentPage) in workspace \(workspace.id)")
        
        // Ensure we're not already loading
        if isLoadingMore { return }
        
        isLoading = true
        isLoadingMore = !threads.isEmpty
        
        ChatService.shared.getThreadsList(
            page: currentPage,
            pageSize: pageSize,
            workspaceId: workspace.id
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                self.isLoadingMore = false
                
                switch result {
                case .success(let response):
                    // Handle success
                    if isRefresh {
                        // Replace all threads on refresh
                        self.threads = response.threads
                    } else {
                        // Append new threads
                        self.threads.append(contentsOf: response.threads)
                    }
                    
                    self.totalThreads = response.total
                    
                    // Check if we have more pages
                    self.hasMorePages = self.threads.count < response.total
                    
                    print("📱 THREAD-HISTORY - Loaded \(response.threads.count) threads. Total: \(response.total)")
                    
                case .failure(let error):
                    // Handle error
                    self.errorMessage = error.localizedDescription
                    print("📱 THREAD-HISTORY - Error loading threads: \(error)")
                }
            }
        }
    }
    
    // Asynchronous refresh for SwiftUI's refreshable modifier
    private func refreshThreadsAsync() async {
        await withCheckedContinuation { continuation in
            refreshThreads()
            continuation.resume()
        }
    }
}

// MARK: - Supporting Views

struct ThreadCard: View {
    let thread: ThreadInfo
    var isSelected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(thread.agentName)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formatDate(thread.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Thread ID: \(thread.threadId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatWorkspaceId(thread.workspaceId))
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func formatWorkspaceId(_ id: String) -> String {
        return id.replacingOccurrences(of: "_", with: ".")
    }
}

// MARK: - Thread List Item

struct ThreadListItem: View {
    let thread: ThreadInfo
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Thread information
            VStack(alignment: .leading, spacing: 4) {
                Text(thread.agentName)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // Thread creation date
                    Text(formatDate(thread.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Workspace indicator
                    Text(formatWorkspaceId(thread.workspaceId))
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Chevron indicating it's tappable
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
    }
    
    // Helper functions for formatting
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        
        if let date = dateFormatter.date(from: dateString) {
            // Always show the full date and time in a consistent format
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "M/d/yyyy, h:mm:ss a"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func formatWorkspaceId(_ id: String) -> String {
        // Format the ID in a user-friendly way
        let parts = id.replacingOccurrences(of: "_", with: ".").components(separatedBy: ".")
        if parts.count >= 2 {
            return parts[0]
        }
        return id
    }
}

// MARK: - Preview

struct ThreadHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ThreadHistoryView()
                .environmentObject(AppState())
        }
    }
}
