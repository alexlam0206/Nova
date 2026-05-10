import SwiftUI

struct TabbarView: View {
    var safeAreaBottomPadding: CGFloat = 0
    @State private var showSettings: Bool = false

    var body: some View {
        TabView {
            ForEach(Tabs.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.image, role: tab == .search ? .search : nil) {
                    TabContent(safeAreaBottomPadding: safeAreaBottomPadding, tab: tab, showSettings: $showSettings)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct TabContentToolbar: View {
    @Binding var showSettings: Bool
    var body: some View {
        Button(action: { showSettings = true }) {
            Image(systemName: "ellipsis")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
        }
    }
}


#Preview {
    ContentView()
}
