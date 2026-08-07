//
//  FolderManager.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 06/04/2026.
//

import Foundation
import Combine
import UniformTypeIdentifiers
import ImageIO

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import UIKit
import Combine
import MediaPlayer

final class FolderManager: ObservableObject {
    @Published var musicFolder: URL?
    private let bookmarkKey = "SelectedMusicFolderBookmark"
    
    init() {
        restoreFolderFromBookmark()
    }
    
    func savePickedFolder(_ folderURL: URL) {
        let didAccess = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let bookmarkData = try folderURL.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            musicFolder = folderURL
        } catch {
            print("Failed to save bookmark:", error)
        }
    }
    
    func restoreFolderFromBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                if url.startAccessingSecurityScopedResource() {
                    if let newBookmark = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
                        UserDefaults.standard.set(newBookmark, forKey: bookmarkKey)
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            musicFolder = url
        } catch {
            print("Failed to resolve bookmark:", error)
        }
    }
    
    func withAccessToFolder<T>(_ body: (URL) throws -> T) rethrows -> T? {
        guard let url = musicFolder else { return nil }
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        return try body(url)
    }

    
    func writeFileToDir() {
        let directory = musicFolder!
        let fileURL = directory.appending(path: "example.txt")
        
        // 3. Prepare content
        let content = "Hello, this is a file saved from SwiftUI!"
        
        // 4. Try writing the file atomically to ensure safety
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Saved successfully to Documents!")
        } catch {
            print("Failed to save: \(error.localizedDescription)")
        }
    }
    
    func clearSavedFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        musicFolder = nil
    }
    
    deinit {
        musicFolder?.stopAccessingSecurityScopedResource()
        musicFolder = nil
    }
}
