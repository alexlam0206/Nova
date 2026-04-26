import SwiftUI

extension View {
    @ViewBuilder
    func matchedTransitionSafe(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func navigationZoomSafe(sourceID: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26, *) {
            self.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            self
        }
    }
}
