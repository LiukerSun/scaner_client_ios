import SwiftUI

struct ScannerRootView: View {
    var body: some View {
        TabView {
            ScannerHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
            ScannerSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.2.fill")
                    Text("设置")
                }
        }
    }
}
