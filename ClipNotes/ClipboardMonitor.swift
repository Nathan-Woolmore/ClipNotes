//
//  ClipboardMonitor.swift
//  ClipNotes
//
//  Created by Nate on 05/04/2024.
//

import AppKit

class ClipboardMonitor {
    private var pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var timer: Timer?
    
    var onNewClipboardContent: ((String) -> Void)?

    init() {
        self.changeCount = pasteboard.changeCount
    }

    func startMonitoring() {
        stopMonitoring() // Ensure no previous timer is running
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.pasteboard.changeCount != self.changeCount {
                self.changeCount = self.pasteboard.changeCount
                if let content = self.pasteboard.string(forType: .string) {
                    self.onNewClipboardContent?(content)
                }
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopMonitoring()
    }
}
