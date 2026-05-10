import SwiftUI

struct MiniPlayerView: View {
    private let height: CGFloat = 60
    @EnvironmentObject private var player: PlayerManager
    @Binding var showQueue: Bool

    var body: some View {
        GlassContainer(cornerRadius: height / 2) {
            HStack(spacing: 15) {
                PlayerInfo(size: .init(width: 48, height: 48))

                Spacer(minLength: 0)

                Button(action: { showQueue = true }) {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                }

                Button(action: { player.togglePlayPause() }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                }

                Button(action: { player.next() }) {
                    Image(systemName: "forward.fill")
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: height / 2, style: .continuous))
    }
}
