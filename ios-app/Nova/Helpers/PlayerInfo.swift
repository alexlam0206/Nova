import SwiftUI

struct PlayerInfo: View {
    var size: CGSize
    @EnvironmentObject private var player: PlayerManager
    var body: some View {
        HStack(spacing: 12) {
            RemoteImageView(urlString: player.coverURLString, width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: size.height / 4, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Some Apple Music Title")
                    .font(.callout)
                
                Text("Some Artist Name")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .lineLimit(1)
        }
    }
}
