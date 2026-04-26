import SwiftUI
import UIKit

struct VisualEffect: UIViewRepresentable {
    var effect: UIVisualEffect?
    let effectView = UIVisualEffectView(effect: nil)

    func makeUIView(context: Context) -> UIVisualEffectView {
        effectView.effect = effect
        effectView.backgroundColor = .clear
        effectView.isOpaque = false
        effectView.clipsToBounds = true
        return effectView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { }
}
