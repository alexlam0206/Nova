import SwiftUI

struct PlayerInfo: View {
    var size: CGSize
    @EnvironmentObject private var player: PlayerManager
    var body: some View {
        HStack(spacing: 12) {
            RemoteImageView(urlString: player.currentSong?.artworkURL?.absoluteString, width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentSong?.title ?? "Not Playing")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(player.currentSong?.artist ?? "—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
