//
//  EditClipboardItemView.swift
//  ClipNotes
//
//  Created by Nate on 04/04/2024.
//
import SwiftUI

struct EditClipboardItemView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var clipboardItem: ClipboardItem
    @Environment(\.presentationMode) var presentationMode
    @State private var editedContent: String
    @Binding var clipboardItems: [ClipboardItem]
    let saveData: () -> Void
    @State private var showDeleteConfirmation = false

    init(clipboardItem: Binding<ClipboardItem>, clipboardItems: Binding<[ClipboardItem]>, saveData: @escaping () -> Void) {
        self._clipboardItem = clipboardItem
        self._editedContent = State(initialValue: clipboardItem.wrappedValue.content)
        self._clipboardItems = clipboardItems
        self.saveData = saveData
    }

    var body: some View {
        VStack {
            // Text editor for editing the clipboard item content
            TextEditor(text: $editedContent)
                .padding()

            HStack {
                // Save button
                Button(action: {
                    clipboardItem.content = editedContent
                    saveData()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .buttonStyle(BlueButtonStyle())

                // Copy button
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(editedContent, forType: .string)
                }) {
                    Text("Copy")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : .accentColor)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())

                // Cancel button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()

                // Delete button
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Text("Delete")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
        .frame(width: 800, height: 600)
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Confirmation"),
                message: Text("Are you sure you want to delete this clipboard item?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteClipboardItem()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }

    // Delete the current clipboard item
    func deleteClipboardItem() {
        if let index = clipboardItems.firstIndex(where: { $0.id == clipboardItem.id }) {
            clipboardItems.remove(at: index)
            saveData()
        }
    }
}
