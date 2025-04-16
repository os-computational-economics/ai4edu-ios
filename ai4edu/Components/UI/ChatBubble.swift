//
//  ChatBubble.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//

import SwiftUI
import Foundation

extension Message {
    static func loadingMessage() -> Message {
        return Message(
            id: UUID().uuidString,
            content: "",
            align: "start"
        )
    }
    
    static func userMessage(_ text: String) -> Message {
        return Message(
            id: UUID().uuidString,
            content: text,
            align: "end",
            currentChatSession: true
        )
    }
    
    var isFromUser: Bool {
        return align == "end"
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let agentName: String
    
    @State private var currentText: String
    
    init(message: ChatMessage, agentName: String) {
        self.message = message
        self.agentName = agentName
        self._currentText = State(initialValue: message.text)
    }
    
    var id: String {
        message.id
    }
    
    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 2) {
            if !message.isFromUser {
                Text(agentName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
            }
            
            MarkdownText(text: message.text, isFromUser: message.isFromUser)
                .id("text-\(message.id)-\(message.text.hashValue)")
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(message.isFromUser ? 
                            Color.blue : 
                            Color(UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1.0)))
                .cornerRadius(20)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.85, alignment: message.isFromUser ? .trailing : .leading)
                .onChange(of: message.text) { oldText, newText in
                    currentText = newText
                }
            
            HStack(alignment: .center, spacing: 8) {
                if !message.isFromUser {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if message.isFromUser {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .id("\(message.id)-container-\(currentText.hashValue)")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension ChatBubble: Equatable {
    static func == (lhs: ChatBubble, rhs: ChatBubble) -> Bool {
        return lhs.message.id == rhs.message.id && 
               lhs.currentText == rhs.currentText &&
               lhs.message.isFromUser == rhs.message.isFromUser
    }
} 
