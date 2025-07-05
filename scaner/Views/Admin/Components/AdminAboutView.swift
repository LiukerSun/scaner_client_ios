import SwiftUI

struct AdminAboutView: View {
    @AppStorage("appMode") private var appMode: String = "admin"
    @State private var versionTapCount = 0
    
    var body: some View {
        List {
            Section(header: Text("信息")) {
                HStack {
                    Text("应用名称")
                    Spacer()
                    Text("商品管理系统")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            versionTapCount += 1
                            if versionTapCount >= 5 {
                                appMode = "anchor"
                                versionTapCount = 0
                            }
                        }
                }
                
                HStack {
                    Text("版本号")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            versionTapCount += 1
                            if versionTapCount >= 5 {
                                appMode = "scanner"
                                versionTapCount = 0
                            }
                        }
                }
            }
        }
        .navigationTitle("关于系统")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct AdminAboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminAboutView()
        }
    }
} 