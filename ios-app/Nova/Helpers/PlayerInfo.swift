import SwiftUI

struct PlayerInfo: View {
    var size: CGSize
    @EnvironmentObject private var player: PlayerManager
    var body: some View {
        HStack(spacing: 12) {
            RemoteImageView(urlString: player.currentSong?.artworkURL?.absoluteString, width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: size.height / 4, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(player.currentSong?.title ?? "Not Playing")
                    .font(.callout)
                    .foregroundStyle(.primary)

                Text(player.currentSong?.artist ?? "—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
        }
    }
}
