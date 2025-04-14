//
//  ChatComponents.swift
//  ai4edu
//
//  Created by Sam Jin on 3/25/25.
//


import SwiftUI
import Foundation

struct ChatMessage: Identifiable {
    let id: String
    var text: String
    let isFromUser: Bool
    let timestamp: Date
}

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
