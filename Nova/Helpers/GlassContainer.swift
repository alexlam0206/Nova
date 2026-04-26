import SwiftUI
import UIKit

struct GlassContainer<Content: View>: View {
    var cornerRadius: CGFloat = 18
    @Environment(\.colorScheme) var colorScheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                content()
                    .glassEffect()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .background(
                        Color.clear
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    )
            } else {
                ZStack {
                    VisualEffect(effect: UIBlurEffect(style: colorScheme == .dark ? .dark : .light))
                    content()
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        }
    }
}

extension GlassContainer where Content == EmptyView {
    init(cornerRadius: CGFloat = 18) {
        self.cornerRadius = cornerRadius
        self.content = { EmptyView() }
    }
}
