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
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                let newBookmark = try url.bookmarkData(
                    options: [],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(newBookmark, forKey: bookmarkKey)
            }
            
            musicFolder = url
        } catch {
            return
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
