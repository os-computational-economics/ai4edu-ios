//
//  AgentFilesView.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI
import Foundation

struct AgentFilesView: View {
    let agent: Agent
    let fileIDs: [String]
    @State private var selectedFileID: String?
    @State private var displayedFiles: [AgentFile] = []
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Agent Files")
                    .font(.headline)
                
                Spacer()
                
                Text("\(displayedFiles.count) Files")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            
            Divider()
            
            // Files list
            if isLoading {
                LoadingView()
            } else if displayedFiles.isEmpty {
                EmptyFilesView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(displayedFiles) { file in
                            FileRow(file: file, isSelected: selectedFileID == file.id) {
                                self.selectedFileID = file.id
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadAgentFiles()
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func loadAgentFiles() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let files = agent.agentFiles.map { fileID, fileName in
                AgentFile(
                    id: fileID,
                    name: fileName,
                    type: Self.getFileType(from: fileName),
                    size: "Unknown",
                    dateAdded: "Unknown"
                )
            }
            
            self.displayedFiles = files.sorted { $0.name < $1.name }
            self.isLoading = false
        }
    }
    
    static func getFileType(from fileName: String) -> FileType {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return .pdf
        case "doc", "docx":
            return .word
        case "xls", "xlsx":
            return .excel
        case "ppt", "pptx":
            return .powerpoint
        case "txt":
            return .text
        case "jpg", "jpeg", "png", "gif", "bmp":
            return .image
        case "mp3", "wav", "m4a":
            return .audio
        case "mp4", "mov", "avi":
            return .video
        default:
            return .other
        }
    }
}

// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("Loading files...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct EmptyFilesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 30)
            
            Text("No files available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("This agent doesn't have any associated files")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct FileRow: View {
    let file: AgentFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                FileTypeIcon(fileType: file.type)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(file.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Color(isSelected ? UIColor.systemGray5 : UIColor.systemBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FileTypeIcon: View {
    let fileType: FileType
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(width: 40, height: 40)
            
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(.white)
        }
    }
    
    private var iconName: String {
        switch fileType {
        case .pdf:
            return "doc.text.fill"
        case .word:
            return "doc.fill"
        case .excel:
            return "chart.bar.doc.horizontal.fill"
        case .powerpoint:
            return "chart.bar.doc.horizontal.fill"
        case .text:
            return "doc.plaintext.fill"
        case .image:
            return "photo.fill"
        case .audio:
            return "music.note.list"
        case .video:
            return "play.rectangle.fill"
        case .other:
            return "doc.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch fileType {
        case .pdf:
            return .red
        case .word:
            return .blue
        case .excel:
            return .green
        case .powerpoint:
            return .orange
        case .text:
            return Color(.systemGray)
        case .image:
            return .purple
        case .audio:
            return .pink
        case .video:
            return .indigo
        case .other:
            return Color(.systemGray)
        }
    }
}

// MARK: - Supporting Types

struct AgentFile: Identifiable {
    let id: String
    let name: String
    let type: FileType
    let size: String
    let dateAdded: String
}