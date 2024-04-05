//
//  DataManager.swift
//  ClipNotes
//
//  Created by Nate on 05/04/2024.
//

import Foundation

class DataManager {
    static let shared = DataManager()

    private init() {} // Private initialization to ensure singleton usage

    func saveData(clipboardItems: [ClipboardItem]) throws {
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(clipboardItems)
            UserDefaults.standard.set(encodedData, forKey: "clipboardItems")
        } catch {
            throw DataManagerError.dataEncodingError(error)
        }
    }


    func loadSavedData() throws -> [ClipboardItem] {
        guard let data = UserDefaults.standard.data(forKey: "clipboardItems") else {
            throw DataManagerError.dataUnavailable
        }
        
        do {
            let savedItems = try JSONDecoder().decode([ClipboardItem].self, from: data)
            return savedItems
        } catch {
            throw DataManagerError.dataDecodingError(error)
        }
    }

}

enum DataManagerError: Error {
    case dataEncodingError(Error)
    case dataDecodingError(Error)
    case dataUnavailable
}

