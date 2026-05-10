import SwiftUI
import UIKit

struct GlassContainer<Content: View>: View {
    var cornerRadius: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer {
                content()
            }
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            ZStack {
                Color.black.opacity(0.55)
                VisualEffect(effect: UIBlurEffect(style: .systemMaterial))
                content()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

extension GlassContainer where Content == EmptyView {
    init(cornerRadius: CGFloat = 18) {
        self.cornerRadius = cornerRadius
        self.content = { EmptyView() }
    }
}