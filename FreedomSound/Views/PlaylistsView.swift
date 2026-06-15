//
//  PlaylistsView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 18/04/2026.
//

import SwiftUI

struct AppleRowButtonStyle: ButtonStyle {

    @State private var didTriggerHaptic = false

    func makeBody(configuration: Configuration) -> some View {

        configuration.label
            .contentShape(Rectangle())
            .background {
                Rectangle()
                    .fill(.primary.opacity(configuration.isPressed ? 0.08 : 0))
                    .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            }
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    didTriggerHaptic = false
                } else if !didTriggerHaptic {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    didTriggerHaptic = true
                }
            }
    }
}

struct RowButtonTest<Content: View>: View {
    let minHeight: CGFloat
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        }
        .buttonStyle(AppleRowButtonStyle())
    }
}

struct PlaylistsView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var manager: FolderAccessManager
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Playlists")

                HStack {
                    Button {
                        router.goToHome()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background {
                                Circle()
                                    .fill(.gray.opacity(0.2))
                            }
                            .foregroundStyle(.gray)
                    }

                    Spacer()
                }
            }
            .padding()
//
            List() {
                if manager.playlists.isEmpty {
                    Text("No playlists found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.playlists) { playlist in
                            RowButtonTest(minHeight: 44) {
                                manager.selectPlaylist(playlist)
                                router.goToPlaylistSongs()
                            } content: {
                                HStack {
                                    Text(playlist.name)
                                        .lineLimit(1)

                                    Spacer()

                                    Text("\(playlist.trackFileNames.count)")
                                        .foregroundStyle(.secondary)

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                }
            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    PlaylistsView()
}
