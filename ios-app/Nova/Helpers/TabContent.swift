import SwiftUI

struct TabContent: View {
    @State private var searchText: String = ""
    var safeAreaBottomPadding: CGFloat
    var tab: Tabs = .home
    var body: some View {
        switch tab {
        case .home:
            NavigationStack {
                List {
                }
                .navigationTitle("Home")
                .safeAreaPadding(.bottom, safeAreaBottomPadding)
            }
        case .new:
            NavigationStack {
                List {
                }
                .navigationTitle("What's New")
                .safeAreaPadding(.bottom, safeAreaBottomPadding)
            }
        case .radio:
            NavigationStack {
                List {
                }
                .navigationTitle("Radio")
                .safeAreaPadding(.bottom, safeAreaBottomPadding)
            }
        case .library:
            NavigationStack {
                List {
                }
                .navigationTitle("Library")
                .safeAreaPadding(.bottom, safeAreaBottomPadding)
            }
        case .search:
            NavigationStack {
                List {
                }
                .navigationTitle("Search")
                .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search..."))
                .safeAreaPadding(.bottom, safeAreaBottomPadding)
            }
        }
    }
}
