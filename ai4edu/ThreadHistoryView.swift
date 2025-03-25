//
//  ChatHistoryView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI

struct ThreadHistoryView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var threads: [ThreadInfo] = []
    @State private var selectedThreadId: String? = nil
    @State private var currentPage: Int = 1
    @State private var pageSize: Int = 20
    @State private var totalThreads: Int = 0
    @State private var isLoading: Bool = false
    @State private var isLoadingMore: Bool = false
    @State private var hasMorePages: Bool = true
    @State private var errorMessage: String? = nil
    @State private var showDebugAlert: Bool = false
    @State private var debugMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with debug button
            HStack {
                Text("Chat History")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    refreshThreads()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
                
                Button(action: {
                    let workspaceId = appState.currentWorkspace?.id ?? "none"
                    showDebugAlert = true
                    debugMessage = "Workspace ID: \(workspaceId)\nThreads count: \(threads.count)\nTotal threads: \(totalThreads)\nCurrent page: \(currentPage)"
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
            .overlay(
                Divider(),
                alignment: .bottom
            )
            
            if isLoading && threads.isEmpty {
                Spacer()
                ProgressView("Loading threads...")
                Spacer()
            } else if let error = errorMessage, threads.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Error loading chat history")
                        .font(.headline)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button("Try Again") {
                        refreshThreads()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                Spacer()
            } else if threads.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No chat history found")
                        .font(.headline)
                    
                    Text("Start a new conversation with an agent to see your chat history")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
                .padding()
                Spacer()
            } else {
                // Thread list with infinite scroll
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(threads) { thread in
                            NavigationLink(destination: ChatThreadDetailView(thread: thread)) {
                                ThreadCard(thread: thread, isSelected: thread.id == selectedThreadId)
                                    .onTapGesture {
                                        selectedThreadId = thread.id
                                    }
                            }
                            .buttonStyle(PlainButtonStyle()) // Remove default NavigationLink styling
                            .id(thread.id) // Add ID for better list management
                            
                            // Load more trigger when reaching the last item
                            if thread.id == threads.last?.id {
                                loadMoreTrigger
                            }
                        }
                        
                        // Loading indicator at the bottom
                        if isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Chat History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if threads.isEmpty {
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
    
    // Helper view that triggers loading more data
    private var loadMoreTrigger: some View {
        Group {
            if hasMorePages {
                Rectangle()
                    .frame(height: 20)
                    .foregroundColor(.clear)
                    .onAppear {
                        loadMoreIfNeeded()
                    }
            } else {
                // End of list indicator
                if !threads.isEmpty {
                    Text("End of History")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func refreshThreads() {
        // Reset pagination state
        currentPage = 1
        threads = []
        hasMorePages = true
        
        // Load first page
        loadThreads(isRefresh: true)
    }
    
    private func loadMoreIfNeeded() {
        if !isLoadingMore && hasMorePages {
            loadMoreThreads()
        }
    }
    
    private func loadMoreThreads() {
        // Check if we can load more pages
        guard hasMorePages && !isLoadingMore else { return }
        
        // Load next page
        currentPage += 1
        loadThreads(isMore: true)
    }
    
    private func loadThreads(isRefresh: Bool = false, isMore: Bool = false) {
        if isRefresh {
            isLoading = true
            errorMessage = nil
        } else if isMore {
            isLoadingMore = true
        }
        
        // Get current workspace ID from app state
        guard let workspace = appState.currentWorkspace, !workspace.id.isEmpty else {
            print("📱 THREAD-HISTORY - ERROR: No current workspace selected!")
            self.isLoading = false
            self.isLoadingMore = false
            self.errorMessage = "No workspace selected. Please select a workspace first."
            return
        }
        
        let workspaceId = workspace.id
        print("📱 THREAD-HISTORY - Loading threads for workspace: '\(workspaceId)' (Page: \(currentPage))")
        
        ChatService.shared.getThreadsList(page: currentPage, pageSize: pageSize, workspaceId: workspaceId) { result in
            // Reset loading states
            if isRefresh {
                self.isLoading = false
            } else if isMore {
                self.isLoadingMore = false
            }
            
            switch result {
            case .success(let response):
                print("📱 THREAD-HISTORY - Received \(response.threads.count) threads (Total: \(response.total))")
                
                if isRefresh {
                    self.threads = response.threads
                } else if isMore {
                    // Append new threads to existing list
                    self.threads.append(contentsOf: response.threads)
                }
                
                self.totalThreads = response.total
                
                // Check if we've loaded all threads
                self.hasMorePages = self.threads.count < self.totalThreads
                
                // Debug: print all threads
                if response.threads.isEmpty {
                    print("📱 THREAD-HISTORY - No more threads found")
                } else {
                    print("📱 THREAD-HISTORY - Loaded \(response.threads.count) more threads. Total loaded: \(self.threads.count) of \(self.totalThreads)")
                }
                
            case .failure(let error):
                print("📱 THREAD-HISTORY - Error loading threads: \(error)")
                if isRefresh {
                    self.errorMessage = error.localizedDescription
                }
                
                // Set debug message for alert
                self.debugMessage = "Error: \(error.localizedDescription)\nWorkspace ID: '\(workspaceId)'"
                self.showDebugAlert = true
            }
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
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
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

// MARK: - Preview

struct ThreadHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ThreadHistoryView()
                .environmentObject(AppState())
        }
    }
}
