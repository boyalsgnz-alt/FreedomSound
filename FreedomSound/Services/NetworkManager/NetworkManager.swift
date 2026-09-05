//
//  NetworkManager.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 28/06/2026.
//

import Foundation
import Combine

private struct GeneratePlaylistRequest: Encodable {
    let limit: Int
    let onlyAvailableTracks: Bool
    let playlistName: String
    let fileName: String
    let generateFile: Bool
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL layout."
        case .invalidResponse:
            return "The server sent an unexpected response."
        case .serverError(let code):
            return "Server returned status \(code)."
        }
    }
}

@MainActor
final class NetworkManager: ObservableObject {
    @Published var isLoading = false

    /**
     Asks the server to generate a playlist and returns the filenames it picked. `playlistName`/`fileName`
     are sent because the API requires them, but are unused server-side for now (reserved for a future
     server-side .m3u generation) — the client is the one writing the .m3u locally via `PlaylistWriter`.
     */
    func generatePlaylist(named playlistName: String, limit: Int = 25) async throws -> [String] {
        guard let url = URL(string: "http://192.168.0.214:3333/playlists/generate") else {
            throw NetworkError.invalidURL
        }

        let body = GeneratePlaylistRequest(
            limit: limit,
            onlyAvailableTracks: true,
            playlistName: playlistName,
            fileName: playlistName,
            generateFile: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        isLoading = true
        defer { isLoading = false }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let dataAsString = String(data: data, encoding: .utf8)
            print(dataAsString)
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode([String].self, from: data)
    }
}
