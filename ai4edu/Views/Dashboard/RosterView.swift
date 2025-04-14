//
//  RosterView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//

import SwiftUI

struct RosterView: View {
    @EnvironmentObject private var appState: AppState
    @State private var users: [User] = []
    @State private var isLoading: Bool = true
    @State private var isLoadingMore: Bool = false
    @State private var currentPage: Int = 1
    @State private var totalUsers: Int = 0
    @State private var hasMorePages: Bool = true
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var currentWorkspaceId: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading && users.isEmpty {
                Spacer()
                ProgressView("Loading roster...")
                    .padding()
                Spacer()
            } else if users.isEmpty {
                emptyStateView()
            } else {
                rosterListView()
            }
        }
        .onAppear {
            loadUsersIfNeeded()
        }
        .onChange(of: appState.currentWorkspace?.id) { oldId, newId in
            if let newWorkspaceId = newId, newWorkspaceId != currentWorkspaceId {
                currentWorkspaceId = newWorkspaceId
                resetAndReload()
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 40)
            
            Text("No users found")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("There are no users enrolled in this workspace yet.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func rosterListView() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("User ID")
                    .fontWeight(.semibold)
                    .frame(width: 80, alignment: .leading)
                
                Text("Student ID")
                    .fontWeight(.semibold)
                    .frame(width: 100, alignment: .leading)
                
                Text("Name")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(Color(UIColor.secondarySystemBackground))
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(users) { user in
                        HStack {
                            Text("\(user.userId)")
                                .font(.subheadline)
                                .frame(width: 80, alignment: .leading)
                            
                            Text(user.studentId)
                                .font(.subheadline)
                                .frame(width: 100, alignment: .leading)
                            
                            Text(user.fullName)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            Divider(),
                            alignment: .bottom
                        )
                    }
                    
                    if isLoadingMore {
                        ProgressView("Loading more...")
                            .padding()
                    } else if !hasMorePages && !users.isEmpty {
                        VStack(spacing: 8) {
                            Divider()
                            Text("End of User List")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 12)
                        }
                    }
                    
                    if hasMorePages {
                        Color.clear
                            .frame(height: 50)
                            .onAppear {
                                loadMoreIfNeeded()
                            }
                    }
                }
            }
            .refreshable {
                resetAndReload()
            }
            
            HStack {
                Text("Showing \(users.count) of \(totalUsers) user\(totalUsers == 1 ? "" : "s")")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal)
            .background(Color(UIColor.secondarySystemBackground))
        }
    }
    
    private func loadUsersIfNeeded() {
        if let workspaceId = appState.currentWorkspace?.id, workspaceId != currentWorkspaceId {
            currentWorkspaceId = workspaceId
            resetAndReload()
        } else if users.isEmpty {
            loadUserList()
        }
    }
    
    private func resetAndReload() {
        currentPage = 1
        users = []
        hasMorePages = true
        loadUserList()
    }
    
    private func loadMoreIfNeeded() {
        if !isLoadingMore && hasMorePages {
            currentPage += 1
            loadMoreUsers()
        }
    }
    
    private func loadMoreUsers() {
        guard let workspaceId = appState.currentWorkspace?.id, !isLoadingMore else { return }
        
        isLoadingMore = true
        
        let formattedWorkspaceId = workspaceId.replacingOccurrences(of: ".", with: "_")
        
        APIService.shared.fetchUserList(
            page: currentPage,
            pageSize: 10,
            workspaceId: formattedWorkspaceId
        ) { result in
            DispatchQueue.main.async {
                isLoadingMore = false
                
                switch result {
                case .success(let response):
                    users.append(contentsOf: response.data.items)
                    totalUsers = response.data.total
                    
                    hasMorePages = response.data.items.count >= 10
                    
                case .failure(let error):
                    errorMessage = "Failed to load more users: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func loadUserList() {
        guard let workspaceId = appState.currentWorkspace?.id else { return }
        
        isLoading = true
        
        let formattedWorkspaceId = workspaceId.replacingOccurrences(of: ".", with: "_")
        
        APIService.shared.fetchUserList(
            page: currentPage,
            pageSize: 10,
            workspaceId: formattedWorkspaceId
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    users = response.data.items
                    totalUsers = response.data.total
                    hasMorePages = response.data.items.count >= 10
                    
                case .failure(let error):
                    errorMessage = "Failed to load users: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}
