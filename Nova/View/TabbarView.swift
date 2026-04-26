import SwiftUI

struct TabbarView: View {
    var safeAreaBottomPadding: CGFloat = 0
    var body: some View {
        TabView {
            ForEach(Tabs.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.image, role: tab == .search ? .search : nil) {
                    TabContent(safeAreaBottomPadding: safeAreaBottomPadding, tab: tab)
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
