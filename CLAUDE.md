# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

FreedomSound is a personal iOS music player (SwiftUI). It reads songs and `.m3u` playlists directly from a
user-selected folder (e.g. synced via Documents/Files), rather than syncing through Apple Music/Spotify-style
libraries. See `README.md` for the full rationale. Built by a TypeScript/JS full-stack dev who is new to Swift and
has been leaning on AI heavily for the Swift/iOS-specific parts — expect some rough edges and be direct about
suggesting cleaner Swift/SwiftUI idioms where they apply.

Note: `FreedomSound.xcodeproj/` is listed in `.gitignore` and is not tracked in git — project settings changes made
in Xcode won't show up in `git status`/diffs.

## Commands

There's no CocoaPods/SPM package to install; this is a plain Xcode project. Build/test from the command line with
`xcodebuild`, or open `FreedomSound.xcodeproj` in Xcode.

```bash
# Build for the simulator
xcodebuild -project FreedomSound.xcodeproj -scheme FreedomSound \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run all tests (unit + UI)
xcodebuild -project FreedomSound.xcodeproj -scheme FreedomSound \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test (Swift Testing syntax, not XCTest)
xcodebuild -project FreedomSound.xcodeproj -scheme FreedomSound \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FreedomSoundTests/FreedomSoundTests/example test
```

Tests use the new **Swift Testing** framework (`import Testing`, `@Test`, `#expect`) in `FreedomSoundTests`, not
XCTest — `FreedomSoundUITests` still uses `XCTest`/`XCUIApplication` since UI testing requires it. There is
currently no real test coverage (the one unit test is an empty placeholder).

There is no lint/format tooling configured in the repo.

## Architecture

The app wires up a small dependency graph by hand in `FreedomSoundApp.swift` (no DI framework) and pushes the
pieces into the SwiftUI environment as `@StateObject`/`@EnvironmentObject`. Views pull what they need via
`@EnvironmentObject`.

**Data flow, folder → playable library:**

1. `FolderManager` (`Services/FolderManager/`) holds the user-picked music folder as a security-scoped bookmark
   (persisted in `UserDefaults`, since this is a sandboxed folder outside the app's container). All folder access
   must go through `withAccessToFolder { url in ... }`, which starts/stops the security scope.
2. `LibraryScanner` walks that folder (non-recursively) and returns URLs for audio files and `.m3u*` playlist
   files.
3. `MetadataParser` turns those URLs into `Track`s (title/artist via `AVAsset` common metadata, parsed concurrently
   in batches) and `Playlist`s (hand-rolled `.m3u`/`#EXTM3U` parser — playlists reference tracks by filename in
   `trackFileNames`, not by `Track.id`, so matching them up is a manual lookup on the consumer side).
4. `LibraryCoordinator` orchestrates steps 1–3 (`loadLibrary()`) and writes the results into `LibraryStore`
   (`@Published var tracks`, `@Published var playlists` — the single source of truth for the UI). It also wires
   `PlaybackQueue.$currentTrack` → `AudioEngine.play(track:)` via Combine, so changing the current track is what
   actually starts playback.
5. `FreedomSoundApp` re-triggers `loadLibrary()` via `.task(id: folderManager.musicFolder)` whenever the picked
   folder changes.

**Playback:**

- `PlaybackQueue` is queue/UI state only (current track, shuffle, repeat mode, ordered track list) — it has no
  knowledge of `AVAudioPlayer`. `enableShuffle()`/`nextTrack()`/`prevTrack()` mutate `currentIndex` and
  `currentTrack`; setting `currentTrack` is what `LibraryCoordinator`'s Combine subscription picks up to hand off
  to playback.
- `AudioEngine` owns the actual `AVAudioPlayer`, publishes transport state (`isPlaying`, `currentTime`, `duration`),
  handles `AVAudioSession` interruptions, and calls `onTrackFinished` (wired to `playbackQueue.nextTrack()`) when a
  track ends.
- `LockScreenManager` mirrors `PlaybackQueue`/`AudioEngine` state into `MPNowPlayingInfoCenter` and wires
  `MPRemoteCommandCenter` (lock screen / Control Center transport controls) back into those two objects.
- `ArtworkLoader` is a singleton with its own `NSCache` + in-flight `Task` de-duping, used both by the lock screen
  and by list/detail views, to avoid re-extracting/re-decoding artwork from `AVAsset` metadata repeatedly.

**Other services:**

- `Services/KMeans.swift` + `Views/KMeansBackground.swift`: k-means clustering over artwork colors, used to derive
  a background gradient/theme from the currently playing track's artwork.
- `Services/NetworkManager/NetworkManager.swift`: talks to a local dev server (`http://192.168.0.218:3000/...`) for
  an in-progress playlist-generation feature — the hardcoded LAN IP means this only works on the author's own
  network and will need to become configurable before this feature is usable elsewhere.
- `Services/utils.swift`: local notification setup, including a "your app is about to expire" reminder computed
  from the embedded provisioning profile's expiration date (relevant for free/personal-team signing, where builds
  expire after ~7 days).

**Views** (`Views/`) are grouped by feature rather than by type: `ContentView` hosts a two-tab `TabView`
(`LibraryView`, `SettingsView`); `LibraryView`/`SongListView`/`SongListContent`/`MusicRowView`/`PlaylistsView` render
the library; `CurrentlyPlayingView`/`FloatingPlayer` render playback UI; `Widgets/` holds small standalone
components (e.g. `CountdownView` for the expiry countdown).
