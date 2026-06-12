//
//  Router.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 16/04/2026.
//

import SwiftUI
import Combine


enum AppScreen: Equatable {
    case home
    case playlists
    case playlistSongs
    case settings
    case viewtester

    var iconName: String {
        switch self {
        case .home:
            return "music.note.house"
        case .playlists:
            return "music.note.list"
        case .playlistSongs:
            return "music.note.list"
        case .settings:
            return "gearshape"
        case .viewtester:
            return "paintbrush.pointed"
        }
    }
}

@MainActor
final class Router: ObservableObject {
    @Published var currentScreen: AppScreen = .home

    func goToHome() {
        currentScreen = .home
    }

    func goToPlaylists() {
        currentScreen = .playlists
    }

    func goToPlaylistSongs() {
        currentScreen = .playlistSongs
    }

    func goToSettings() {
        currentScreen = .settings
    }

    func goToViewTester() {
        currentScreen = .viewtester
    }
}
