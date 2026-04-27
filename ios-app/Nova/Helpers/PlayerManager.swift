import Foundation
import Combine

final class PlayerManager: ObservableObject {
    static let shared = PlayerManager()

    @Published var isFavorited: Bool = false
    // Use Cataas cat image as cover preview
    @Published var coverURLString: String = "https://cataas.com/cat"

    func toggleFavorite() {
        isFavorited.toggle()
    }
}
