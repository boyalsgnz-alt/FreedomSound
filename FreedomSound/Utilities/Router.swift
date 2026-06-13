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

    var navigationDepth: Int {
        switch self {
        case .home, .settings:
            return 0
        case .playlists, .viewtester:
            return 1
        case .playlistSongs:
            return 2
        }
    }
}

enum ScreenTransitionDirection {
    case forward
    case backward

    var insertionEdge: Edge {
        self == .forward ? .trailing : .leading
    }

    var removalEdge: Edge {
        self == .forward ? .leading : .trailing
    }
}

@MainActor
final class Router: ObservableObject {
    @Published var currentScreen: AppScreen = .home
    @Published var transitionDirection: ScreenTransitionDirection = .forward

    func goToHome() {
        go(to: .home)
    }

    func goToPlaylists() {
        go(to: .playlists)
    }

    func goToPlaylistSongs() {
        go(to: .playlistSongs)
    }

    func goToSettings() {
        go(to: .settings)
    }

    func goToViewTester() {
        go(to: .viewtester)
    }

    func go(to screen: AppScreen) {
        guard screen != currentScreen else { return }

        transitionDirection = screen.navigationDepth >= currentScreen.navigationDepth ? .forward : .backward

        if screen.navigationDepth == 0 && currentScreen.navigationDepth == 0 {
            currentScreen = screen
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                currentScreen = screen
            }
        }
    }
}
