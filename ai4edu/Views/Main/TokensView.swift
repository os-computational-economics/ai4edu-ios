//
//  TokensView.swift
//  ai4edu
//
//  Created by Sam Jin on 4/12/25.
//

import SwiftUI
import Combine

struct TokensView: View {
    @State private var showTokens: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                showTokens.toggle()
            }) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(width: 25, height: 25)
                    
                    Text("Show Tokens")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: showTokens ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            if showTokens {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Token Information:")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.top, 5)
                    
                    if let jwtData = TokenManager.shared.decodeToken() {
                        VStack(alignment: .leading) {
                            Text(jwtData.formattedString())
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(4)
                            
                            if !jwtData.workspaceRoles.isEmpty {
                                Divider()
                                    .padding(.vertical, 5)
                                
                                Text("Workspace Roles:")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(jwtData.workspaceRoles.sorted(by: { $0.key < $1.key }), id: \.key) { workspace, role in
                                        HStack {
                                            Text(workspace)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(role.capitalized)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(4)
                            }
                        }
                    } else {
                        Text("Unable to decode token")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    Text("Access Token (Raw):")
                        .font(.caption)
                        .fontWeight(.bold)
                    
                    if let accessToken = TokenManager.shared.getAccessToken() {
                        ScrollView {
                            Text(accessToken)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(4)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 100)
                    } else {
                        Text("No access token")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("Refresh Token (Raw):")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.top, 5)
                    
                    if let refreshToken = TokenManager.shared.getRefreshToken() {
                        ScrollView {
                            Text(refreshToken)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(4)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 100)
                    } else {
                        Text("No refresh token")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
        }
    }
}
