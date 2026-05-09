import SwiftUI

struct ContentView: View {
    private let miniPlayerHeight: CGFloat = 60
    @State private var expandMiniPlayer: Bool = false
    @State private var dragOffset: CGFloat = 0
    @Namespace private var animation
    @StateObject private var player = PlayerManager.shared

    var body: some View {
        ZStack {
            AnimatedBackground()

            TabbarView(safeAreaBottomPadding: miniPlayerHeight)
                .environmentObject(player)
                .overlay(alignment: .bottom) {
                    MiniPlayerView()
                        .matchedTransitionSafe(id: "MINIPLAYER", in: animation)
                        .onTapGesture {
                            withAnimation {
                                dragOffset = 0
                                expandMiniPlayer = true
                            }
                        }
                        .offset(y: -miniPlayerHeight)
                        .padding(.horizontal, 15)
                }
                .ignoresSafeArea(.keyboard, edges: .all)
                .fullScreenCover(isPresented: $expandMiniPlayer) {
                    GeometryReader { geo in
                        ExpandedMiniPlayerContent(dragOffset: $dragOffset,
                                                   expandMiniPlayer: $expandMiniPlayer,
                                                   animation: animation)
                            .environmentObject(player)
                            .padding(.top, geo.safeAreaInsets.top + 8)
                            .ignoresSafeArea()
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = max(0, value.translation.height)
                                    }
                                    .onEnded { value in
                                        let shouldClose = value.translation.height > 120 || value.predictedEndTranslation.height > 150
                                        if shouldClose {
                                            withAnimation {
                                                expandMiniPlayer = false
                                            }
                                        } else {
                                            withAnimation {
                                                dragOffset = 0
                                            }
                                        }
                                    }
                            )
                    }
                }
        }
        .environmentObject(player)
    }
}

private struct ExpandedMiniPlayerContent: View {
    @Binding var dragOffset: CGFloat
    @Binding var expandMiniPlayer: Bool
    var animation: Namespace.ID
    @EnvironmentObject private var player: PlayerManager
    @State private var showMore: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(.primary.opacity(0.5))
                .frame(width: 35, height: 3)
                .padding(.top, 8)

            // Top row: close button
            HStack {
                Button(action: { expandMiniPlayer = false }) {
                    Image(systemName: "chevron.down")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { showMore = true }) {
                    Image(systemName: "ellipsis")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer()

            // Album art
            Group {
                if let img = player.artwork {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            }
            .frame(width: 300, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 30, y: 20)

            Spacer()

            // Song info
            VStack(spacing: 6) {
                Text(player.currentSong?.title ?? "Not Playing")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(player.currentSong?.artist ?? "—")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let lyric = player.currentLyric {
                    Text(lyric)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            // Progress bar
            VStack(spacing: 6) {
                ProgressBar(progress: player.progress, duration: player.currentSong?.duration ?? 1)
                    .frame(height: 4)
                    .onTapGesture { } // placeholders — drag handled by gesture below

                HStack {
                    Text(formatTime(player.progress))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatTime(player.currentSong?.duration ?? 0))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Playback controls
            HStack(spacing: 40) {
                Button(action: { player.previous() }) {
                    Image(systemName: "backward.fill")
                        .font(.title)
                        .foregroundStyle(.primary)
                }

                Button(action: { player.togglePlayPause() }) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.primary)
                }

                Button(action: { player.next() }) {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundStyle(.primary)
                }
            }

            Spacer()

            // Bottom row: favorite + extras
            HStack(spacing: 30) {
                Button(action: { player.toggleFavorite() }) {
                    Image(systemName: player.isFavorited ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(player.isFavorited ? .yellow : .secondary)
                }

                Spacer()

                Image(systemName: "airplayaudio")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 16)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = max(0, value.translation.height)
                }
                .onEnded { value in
                    let shouldClose = value.translation.height > 120 || value.predictedEndTranslation.height > 150
                    if shouldClose {
                        expandMiniPlayer = false
                    }
                    dragOffset = 0
                }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .confirmationDialog("More Options", isPresented: $showMore) {
            Button("Add to Playlist") {}
            Button("Share") {}
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Progress Bar
private struct ProgressBar: View {
    let progress: TimeInterval
    let duration: TimeInterval

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.secondary.opacity(0.3))
                Capsule().fill(.primary)
                    .frame(width: max(0, geo.size.width * (progress / max(duration, 1))))
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    ContentView()
}
