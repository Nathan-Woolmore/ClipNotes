//
//  ContentView.swift
//  ClipNotes
//
//  Created by Nate on 01/04/2024.
//
import SwiftUI

// Constants
let maxItemCount = 1000
let truncatTextAfterChar = 100

// Color extension for item text color
extension Color {
    static let itemText = Color(NSColor.labelColor)
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showStatusAlert = false
    @State private var statusMessage = ""
    @State private var clipboardItems: [ClipboardItem] = []
    @State private var lastCopiedItem: String = ""
    @State private var searchText = ""
    @State private var selectedClipboardItem: ClipboardItem?
    @State private var isAlertPresented = false
    
    private let clipboardMonitor = ClipboardMonitor()
    
    // Computed property to filter clipboard items based on search text
    var filteredClipboardItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardItems
        } else {
            return clipboardItems.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            // Search bar
            SearchBarView(searchText: $searchText)
            
            // Clipboard items list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredClipboardItems) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.truncatedContent)
                                    .font(.body)
                                    .padding(.vertical, 8)
                                    .foregroundColor(Color(NSColor.labelColor))
                                
                                Text(formatTimestamp(item.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedClipboardItem = item
                            }
                            
                            Button(action: {
                                ClipboardManager.shared.copyToClipboard(item.content)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(colorScheme == .dark ? .white : .accentColor)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding()
            }
            
            // Bottom toolbar
            HStack {
                Button(action: clearClipboard) {
                    Text("Clear Clipboard")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Group {
                                if colorScheme == .dark {
                                    Color.clear
                                } else {
                                    Color.white
                                }
                            }
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                
                Spacer()
                
                Text("Items: \(clipboardItems.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .alert(isPresented: $showStatusAlert) {
            Alert(title: Text(statusMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(item: $selectedClipboardItem) { item in
            EditClipboardItemView(
                clipboardItem: binding(for: item),
                clipboardItems: $clipboardItems
            ) {
                // Closure to save data
                saveData()
            }
        }
        
        .onAppear {
            do {
                clipboardItems = try DataManager.shared.loadSavedData()
            } catch DataManagerError.dataUnavailable {
                clipboardItems = [] // No saved data available; start with an empty list.
            } catch DataManagerError.dataDecodingError(let error) {
                // Handle decoding errors
                print("Failed to decode saved clipboard data: \(error)")
                statusMessage = "Failed to load saved data."
                showStatusAlert = true
            } catch {
                // Handle any other errors.
                print("An unexpected error occurred: \(error)")
                statusMessage = "An unexpected error occurred."
                showStatusAlert = true
            }
            
            
            clipboardMonitor.onNewClipboardContent = { content in
                DispatchQueue.main.async {
                    self.handleNewClipboardContent(content)
                }
            }
            clipboardMonitor.startMonitoring()
        }.onDisappear {
            // Stop monitoring when the view disappears
            clipboardMonitor.stopMonitoring()
        }
    }
    
    func handleNewClipboardContent(_ content: String) {
        if content != lastCopiedItem {
            if let existingIndex = clipboardItems.firstIndex(where: { $0.content == content }) {
                clipboardItems.remove(at: existingIndex)
            }
            
            let newItem = ClipboardItem(content: content, timestamp: Date())
            clipboardItems.insert(newItem, at: 0)
            
            if clipboardItems.count > maxItemCount {
                clipboardItems.removeLast(clipboardItems.count - maxItemCount)
            }
            
            lastCopiedItem = content
            
            saveData()
        }
    }

    
    
    // Clear the clipboard and remove all items
    func clearClipboard() {
        guard !isAlertPresented else { return }
                isAlertPresented = true
        
        let alert = NSAlert()
        alert.messageText = "Delete all snippets"
        alert.informativeText = "Are you sure you want to clear the clipboard? this action cannot be undone."
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            clipboardItems.removeAll()
            saveData()
        }
        // Reset isAlertPresented flag, ensure UI has time to process the dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAlertPresented = false
        }
    }
    
    // Format timestamp as a string
    func formatTimestamp(_ timestamp: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return dateFormatter.string(from: timestamp)
    }
    
    // Save clipboard items data
    func saveData() {
        do {
            try DataManager.shared.saveData(clipboardItems: clipboardItems)
        } catch DataManagerError.dataEncodingError(let error) {
            // Handle the error, e.g., by logging or showing an alert to the user
            print("Error encoding data: \(error)")
            statusMessage = "Error saving data."
            showStatusAlert = true
        } catch {
            print("An unexpected error occurred: \(error)")
            statusMessage = "An unexpected error occurred saving data."
            showStatusAlert = true
        }
    }

    
    
    // Create a binding for a clipboard item
    func binding(for clipboardItem: ClipboardItem) -> Binding<ClipboardItem> {
        if let index = clipboardItems.firstIndex(where: { $0.id == clipboardItem.id }) {
            return $clipboardItems[index]
        } else {
            // Handle the case when the ClipboardItem is not found, return a binding to a new ClipboardItem instance
            let newClipboardItem = ClipboardItem(content: clipboardItem.content, timestamp: clipboardItem.timestamp)
            clipboardItems.append(newClipboardItem)
            return $clipboardItems[clipboardItems.count - 1]
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}

























