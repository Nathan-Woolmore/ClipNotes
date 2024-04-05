//
//  ClipboardManager.swift
//  ClipNotes
//
//  Created by Nate on 05/04/2024.
//

import AppKit

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private init() {} // Private initialization to ensure singleton usage

    func copyToClipboard(_ item: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item, forType: .string)
    }
    
    func clearClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
    }
}
