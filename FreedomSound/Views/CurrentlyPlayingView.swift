//
//  CurrentlyPlayingView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 12/04/2026.
//

import SwiftUI
import AVFoundation

struct CurrentlyPlayingView: View {
    @State private var loadTask: Task<Void, Never>?
    @Binding var isToggled: Bool
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var playbackMgr: PlaybackQueue
    @State private var isEditingSlider = false
    @State private var artwork: UIImage?
    
    func formatTime(_ time: Double) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    @ViewBuilder
    func controlButton(systemName: String, iconSize: CGFloat = 22, buttonSize: CGFloat = 56, color: Color = .white, circled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .ultraLight))
                .frame(width: buttonSize, height: buttonSize)
                .background {
                    if circled {
                        Circle()
                            .fill(.gray.opacity(0.2))
                    }
                }
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
        }
    }
    
    var body: some View {
        ZStack {
            KMeansGradientBackground(artwork: artwork)
            
            VStack(spacing: 0) {
                // Top bar
                ZStack {
                    Text(playbackMgr.currentPlaylist?.name ?? "Playlist Name")
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    HStack {
                        Button {
                            isToggled.toggle()
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 19, weight: .bold))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                //.foregroundStyle(.gray)
                                .glassEffect(.regular, in: .capsule)
                        }
                        .padding()
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                Group {
                    if let artwork = artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFit()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding()
                    } else {
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding()
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(playbackMgr.currentTrack!.title).font(.system(size: 20, weight: .bold))
                    Text(playbackMgr.currentTrack!.artist).font(.system(size: 16, weight: .light))
                    Slider(
                        value: Binding(
                            get: {
                                audioEngine.currentTime
                            },
                            set: { newValue in
                                audioEngine.currentTime = newValue
                            }
                        ),
                        in: 0...(max(audioEngine.duration, 1)),
                        onEditingChanged: { editing in
                            audioEngine.isScrubbing = editing
                            
                            if !editing {
                                audioEngine.seek(to: audioEngine.currentTime)
                            }
                        }
                    )
                    
                    HStack {
                        Text(formatTime(audioEngine.currentTime))
                        Spacer()
                        Text(formatTime(audioEngine.duration))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }.padding()
                
                Spacer()
                
                HStack(spacing: 4) {
                    controlButton(systemName: "shuffle", iconSize: 18, buttonSize: 44, color: playbackMgr.isShuffled ? .green : .white, circled: false) {
                        playbackMgr.enableShuffle()
                    }
                    controlButton(systemName: "backward.end.fill", iconSize: 32, buttonSize: 50, circled: false) {
                        playbackMgr.prevTrack(currentTime: audioEngine.currentTime)
                    }
                    controlButton(systemName: audioEngine.isPlaying ? "pause.fill" : "play.fill", iconSize: 40, buttonSize: 80) {
                        if audioEngine.isPlaying {
                            audioEngine.pause()
                        } else {
                            audioEngine.resume()
                        }
                    }
                    controlButton(systemName: "forward.end.fill", iconSize: 32, buttonSize: 50, circled: false) {
                        playbackMgr.nextTrack()
                    }
                    controlButton(systemName: playbackMgr.repeatMode.iconName, iconSize: 18, buttonSize: 44, color: playbackMgr.repeatMode.color, circled: false) {
                        playbackMgr.shiftRepeatMode()
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
            }
            .task(id: playbackMgr.currentTrack!.url) {
                if let cached = ArtworkLoader.shared.cachedImage(for: playbackMgr.currentTrack!.url, fullSize: true) {
                    artwork = cached
                    return
                }
                let task = Task {
                    let image = await ArtworkLoader.shared.loadArtwork(for: playbackMgr.currentTrack!.url, fullSize: true).value
                    if !Task.isCancelled {
                        artwork = image
                    }
                }

                loadTask = task
                await task.value
            }
        }
    }
}

/* #Preview {
 CurrentlyPlayingView(file: MusicFile(url: URL(fileURLWithPath: "lol")), isToggled: .constant(true))
 } */
