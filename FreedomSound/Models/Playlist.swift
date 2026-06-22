import Foundation

struct Playlist: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let sourceURL: URL?
    let trackFileNames: [String]
}
