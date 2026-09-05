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
    @EnvironmentObject var libraryStore: LibraryStore
    @EnvironmentObject var playbackMgr: PlaybackQueue
    @EnvironmentObject var libraryCoordinator: LibraryCoordinator
    @Binding var navPath: NavigationPath
    @Binding var floatingPlayerHeight: CGFloat

    @State private var playlistPendingDeletion: Playlist?
    @State private var showDeletionConfirmation = false
    @State private var deletionErrorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if libraryStore.playlists.isEmpty {
                Text("No playlists found")
                    .foregroundStyle(.secondary)
            } else {
                List(libraryStore.playlists, id: \.id) { playlist in
                    RowButtonTest(minHeight: 20) {
                        navPath.append(playlist)
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
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            // Let the swipe's own closing animation play out before the confirmation
                            // appears, instead of both animating at once. Both state changes land
                            // together once the delay is over, rather than one immediately and one
                            // delayed, to avoid an in-between render with only half the state updated.
                            Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                playlistPendingDeletion = playlist
                                showDeletionConfirmation = true
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            playlistPendingDeletion = playlist
                            showDeletionConfirmation = true
                        } label: {
                            Label("Delete Playlist", systemImage: "trash")
                        }
                        .tint(.orange)
                    }
                    .popover(
                        isPresented: Binding(
                            get: { showDeletionConfirmation && playlistPendingDeletion?.id == playlist.id },
                            set: { if !$0 { showDeletionConfirmation = false } }
                        ),
                        // Anchoring to a single point rather than the row's full (wide, short) bounds
                        // avoids a known SwiftUI quirk where a wide anchor rect occasionally makes the
                        // system pick a leading/trailing placement and squeeze the content to fit.
                        attachmentAnchor: .point(.center),
                        arrowEdge: .top
                    ) {
                        deletionConfirmationContent(for: playlist)
                            .presentationCompactAdaptation(.popover)
                    }
                }
                .listStyle(.plain)
                .navigationDestination(for: Playlist.self) { item in
                    SongListView(floatingPlayerHeight: $floatingPlayerHeight, playlist: item)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: floatingPlayerHeight)
                }
                .navigationTitle("Playlists")
            }
        }
        .alert(
            "Couldn't delete playlist",
            isPresented: Binding(
                get: { deletionErrorMessage != nil },
                set: { if !$0 { deletionErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deletionErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private func deletionConfirmationContent(for playlist: Playlist) -> some View {
        VStack(spacing: 14) {
            Text("Delete \"\(playlist.name)\"?")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("This only removes the playlist. Your songs won't be deleted.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            VStack(spacing: 16) {
                Button("Delete Playlist", role: .destructive) {
                    confirmDeletion()
                    showDeletionConfirmation = false
                }
                .frame(maxWidth: .infinity)

                Button("Cancel", role: .cancel) {
                    showDeletionConfirmation = false
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
        }
        .padding()
        .frame(width: 260)
    }

    private func confirmDeletion() {
        guard let playlist = playlistPendingDeletion else { return }
        do {
            // Animated so the row fades and the list collapses smoothly, rather than the row
            // vanishing abruptly.
            try withAnimation {
                try libraryCoordinator.deletePlaylist(playlist)
            }
        } catch {
            deletionErrorMessage = error.localizedDescription
        }
    }
}

//#Preview {
//    PlaylistsView()
//}
