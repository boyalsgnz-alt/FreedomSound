//
//  MusicRowView.swift
//  FreedomSound
//
//  Created by Gaëtan Boyals on 12/04/2026.
//

import SwiftUI

struct MusicRowView: View {
    let file: Track

    @State private var artwork: UIImage?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let artwork {
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
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(file.title)
                    .lineLimit(1)

                Text(file.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .task(id: file.url) {
            if artwork != nil { return }

            if let cached = ArtworkLoader.shared.cachedImage(for: file.url, fullSize: false) {
                artwork = cached
                return
            }

            let task = Task {
                let image = await ArtworkLoader.shared.loadArtwork(for: file.url, fullSize: false).value
                if !Task.isCancelled {
                    artwork = image
                }
            }

            loadTask = task
            await task.value
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }
}
