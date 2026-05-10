import AVKit
import SwiftUI

struct RoutePickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = UIColor.secondaryLabel
        picker.activeTintColor = UIColor.systemBlue
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

struct ContentView: View {
    private let miniPlayerHeight: CGFloat = 60
    @State private var expandMiniPlayer: Bool = false
    @State private var showQueue: Bool = false
    @Namespace private var animation
    @StateObject private var player = PlayerManager.shared

    var body: some View {
        ZStack {
            AnimatedBackground()

            TabbarView(safeAreaBottomPadding: miniPlayerHeight)
                .environmentObject(player)
                .overlay(alignment: .bottom) {
                    MiniPlayerView(showQueue: $showQueue)
                        .matchedTransitionSafe(id: "MINIPLAYER", in: animation)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                expandMiniPlayer = true
                            }
                        }
                        .offset(y: -miniPlayerHeight)
                        .padding(.horizontal, 15)
                }
                .ignoresSafeArea(.keyboard, edges: .all)
                .sheet(isPresented: $expandMiniPlayer) {
                    ExpandedMiniPlayerContent(expandMiniPlayer: $expandMiniPlayer)
                        .environmentObject(player)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showQueue) {
                    QueueView()
                        .environmentObject(player)
                }
        }
        .environmentObject(player)
    }
}

private struct ExpandedMiniPlayerContent: View {
    @Binding var expandMiniPlayer: Bool
    @EnvironmentObject private var player: PlayerManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 8)

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
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Song info
            VStack(spacing: 4) {
                Text(player.currentSong?.title ?? "Not Playing")
                    .font(.title3.bold())
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
                        .padding(.top, 2)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)

            // Progress bar
            VStack(spacing: 6) {
                ProgressBar(progress: player.progress, duration: player.currentSong?.duration ?? 1) { newProgress in
                        player.seek(to: newProgress)
                    }
                    .frame(height: 4)

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
            .padding(.top, 16)

            // Playback controls
            HStack(spacing: 40) {
                Button(action: { player.previous() }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }

                Button(action: { player.togglePlayPause() }) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.primary)
                }

                Button(action: { player.next() }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.top, 16)

            // Bottom row: favorite + share + route picker
            HStack(spacing: 30) {
                Button(action: { player.toggleFavorite() }) {
                    Image(systemName: player.isFavorited ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(player.isFavorited ? .yellow : .primary)
                }
                .opacity(player.currentSong != nil ? 1 : 0.3)
                .disabled(player.currentSong == nil)

                ShareLink(item: player.currentSong?.source ?? "") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
                .opacity(player.currentSong?.source != nil ? 1 : 0.3)
                .disabled(player.currentSong?.source == nil)

                Spacer()

                RoutePickerView()
                    .frame(width: 44, height: 28)
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

// MARK: - Draggable Progress Bar
private struct ProgressBar: View {
    let progress: TimeInterval
    let duration: TimeInterval
    var onSeek: ((TimeInterval) -> Void)?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.secondary.opacity(0.3))
                Capsule().fill(.primary)
                    .frame(width: max(0, geo.size.width * (progress / max(duration, 1))))
            }
            .frame(height: 4)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = min(max(value.location.x / geo.size.width, 0), 1)
                        onSeek?(ratio * duration)
                    }
            )
        }
        .frame(height: 4)
    }
}

// MARK: Queue View
struct QueueView: View {
    @EnvironmentObject private var player: PlayerManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if player.queue.isEmpty {
                    Text("Queue is empty")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(player.queue) { song in
                        HStack(spacing: 12) {
                            RemoteImageView(
                                urlString: song.artworkURL?.absoluteString,
                                width: 48, height: 48
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(song.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(song.artist)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(formatTime(TimeInterval(song.duration)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let idx = player.queue.firstIndex(where: { $0.id == song.id }) {
                                player.playSong(at: idx)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet {
                            player.queue.remove(at: i)
                        }
                    }
                    .onMove { from, to in
                        player.queue.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
