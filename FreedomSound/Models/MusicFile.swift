import Foundation
import UIKit

struct MusicFile: Identifiable, Equatable {
    var id: String { url.path }
    let url: URL
    let fileName: String

    var title: String
    var artist: String

    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        self.title = url.deletingPathExtension().lastPathComponent
        self.artist = "Unknown Artist"
    }
}

struct SongFile: Identifiable, Equatable {
    var id: String { url.path }
    let url: URL
    let fileName: String
    
    var title: String
    var artist: String
    
    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        self.title = url.deletingPathExtension().lastPathComponent
        self.artist = "Unknown Artist"
    }
}

struct Track: Identifiable, Equatable {
    var id: String { url.path }
    let url: URL
    let fileName: String
    
    var title: String
    var artist: String
    
    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        self.title = url.deletingPathExtension().lastPathComponent
        self.artist = "Unknown Artist"
    }
}
