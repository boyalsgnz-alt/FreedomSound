//
//  FloatingPlayer.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 06/04/2026.
//

import SwiftUI
import AVFoundation

struct FloatingPlayerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var playbackMgr: PlaybackQueuee
    @State private var loadTask: Task<Void, Never>?
    @State private var showingFullPlayer = false
    @State private var artwork: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if audioEngine.isPlaying {
                    audioEngine.pause()
                } else {
                    audioEngine.resume()
                }
            } label: {
                Image(systemName: audioEngine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(.gray.opacity(0.2))
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(playbackMgr.currentTrack!.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Text(playbackMgr.currentTrack!.artist)
                    .font(.system(size: 13, weight: .light))
                    .lineLimit(1)
            }

            Spacer()

            Group {
                if let artwork = artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.25))
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingFullPlayer.toggle()
        }
        .padding(12)
        .fullScreenCover(isPresented: $showingFullPlayer) {
            CurrentlyPlayingView(isToggled: $showingFullPlayer)
        }
        .glassEffect(.regular, in: .capsule)
        .clipShape(RoundedRectangle(cornerRadius: 60, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
        .shadow(radius: 8)
        .task(id: playbackMgr.currentTrack!.url) {
            if artwork != nil { return }

            if let cached = ArtworkLoader.shared.cachedImage(for: playbackMgr.currentTrack!.url) {
                artwork = cached
                return
            }

            let task = Task {
                let image = await ArtworkLoader.shared.loadArtwork(for: playbackMgr.currentTrack!.url, fullSize: false).value
                if !Task.isCancelled {
                    artwork = image
                }
            }

            loadTask = task
            await task.value
        }
    }
}

/* #Preview {
    FloatingPlayerView(title: "Titre", artist: "Artiste", artwork: nil, isPlaying: .constant(false))
} */
