//
//  ClipboardItem.swift
//  ClipNotes
//
//  Created by Nate on 04/04/2024.
//

import Foundation

struct ClipboardItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var content: String
    let timestamp: Date
    var truncatedContent: String {
        if content.count > truncatTextAfterChar {
            return String(content.prefix(truncatTextAfterChar)) + "... (truncated)"
        } else {
            return content
        }
    }
}
