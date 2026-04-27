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
        VStack(spacing: 10) {
            Capsule()
                .fill(.primary.opacity(0.6))
                .frame(width: 35, height: 3)

            HStack(spacing: 0) {
                PlayerInfo(size: .init(width: 80, height: 80))
                Spacer(minLength: 0)

                Group {
                    Button(action: { player.toggleFavorite() }) {
                        Image(systemName: player.isFavorited ? "star.fill" : "star")
                    }

                    Button(action: { showMore = true }) {
                        Image(systemName: "ellipsis.circle.fill")
                    }
                }
                .font(.title)
                .foregroundStyle(.primary, .primary.opacity(0.1))
            }
            .padding(.horizontal, 15)

            Spacer()
        }
        .confirmationDialog("More Options", isPresented: $showMore) {
            Button("Add to Playlist") {
                // TODO: implement playlist action
            }
            Button("Share") {
                // TODO: implement share action
            }
            Button("Cancel", role: .cancel) {}
        }
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
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

#Preview {
    ContentView()
}
