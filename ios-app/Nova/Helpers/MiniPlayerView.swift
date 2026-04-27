import SwiftUI

struct MiniPlayerView: View {
    private let height: CGFloat = 60
    
    var body: some View {
        GlassContainer(cornerRadius: height / 2) {
            HStack(spacing: 15) {
                PlayerInfo(size: .init(width: 48, height: 48))

                Spacer(minLength: 0)

                Button(action: {}) {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                }
                .padding(.trailing, 8)

                Button(action: {}) {
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
