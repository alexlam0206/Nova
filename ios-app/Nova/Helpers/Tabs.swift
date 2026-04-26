import Foundation

enum Tabs: CaseIterable {
    case home, new, radio, library, search
    
    /// bottom bar title
    var title: String {
        switch self {
        case .home: return "Home"
        case .new: return "New"
        case .radio: return "Radio"
        case .library: return "Library"
        case .search: return "Search"
        }
    }
    
    /// bottom bar icons
    var image: String {
        switch self {
        case .home: return "house"
        case .new: return "square.grid.2x2.fill"
        case .radio: return "dot.radiowaves.left.and.right"
        case .library: return "square.stack.fill"
        case .search: return "magnifyingglass"
        }
    }
}
