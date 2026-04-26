import SwiftUI

struct ContentView: View {
    private let miniPlayerHeight: CGFloat = 60
    @State private var expandMiniPlayer: Bool = false
    @State private var dragOffset: CGFloat = 0
    @Namespace private var animation

    var body: some View {
        ZStack {
            AnimatedBackground()

            TabbarView(safeAreaBottomPadding: miniPlayerHeight)
                .overlay(alignment: .bottom) {
                    MiniPlayerView()
                        .matchedTransitionSafe(id: "MINIPLAYER", in: animation)
                        .onTapGesture {
                            expandMiniPlayer.toggle()
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
                            .padding(.top, geo.safeAreaInsets.top + 8)
                            .ignoresSafeArea()
                    }
                }
        }
    }
}

private struct ExpandedMiniPlayerContent: View {
    @Binding var dragOffset: CGFloat
    @Binding var expandMiniPlayer: Bool
    var animation: Namespace.ID

    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(.primary.opacity(0.6))
                .frame(width: 35, height: 3)

            HStack(spacing: 0) {
                PlayerInfo(size: .init(width: 80, height: 80))
                Spacer(minLength: 0)

                Group {
                    Button(action: {}) { Image(systemName: "star.circle.fill") }
                    Button(action: {}) { Image(systemName: "ellipsis.circle.fill") }
                }
                .font(.title)
                .foregroundStyle(.primary, .primary.opacity(0.1))
            }
            .padding(.horizontal, 15)

            Spacer()
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = max(0, value.translation.height)
                }
                .onEnded { value in
                    let shouldClose = value.translation.height > 120 || value.predictedEndTranslation.height > 150
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if shouldClose {
                            expandMiniPlayer = false
                        }
                        dragOffset = 0
                    }
                }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

#Preview {
    ContentView()
}
