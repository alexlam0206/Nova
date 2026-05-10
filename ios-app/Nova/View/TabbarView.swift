import SwiftUI

struct TabbarView: View {
    var safeAreaBottomPadding: CGFloat = 0
    @State private var showSettings: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                ForEach(Tabs.allCases, id: \.self) { tab in
                    Tab(tab.title, systemImage: tab.image, role: tab == .search ? .search : nil) {
                        TabContent(safeAreaBottomPadding: safeAreaBottomPadding, tab: tab)
                    }
                }
            }

            HStack {
                Spacer()
                Button(action: { showSettings = true }) {
                    Image(systemName: "person.crop.circle")
                        .font(.title.bold())
                        .foregroundStyle(.red)
                        .padding(14)
                }
            }
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
}