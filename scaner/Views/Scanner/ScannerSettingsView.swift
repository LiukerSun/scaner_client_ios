import SwiftUI

struct ScannerSettingsView: View {
    @AppStorage("isNewWorld") private var isNewWorld: Bool = true
    @State private var versionTapCount = 0
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("信息")) {
                    HStack {
                        Text("扫码端App")
                        Spacer()
                        Text("Scanner")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("版本号")
                        Spacer()
                        Text("2.0.0")
                            .foregroundColor(.gray)
                            .onTapGesture {
                                versionTapCount += 1
                                if versionTapCount >= 5 {
                                    isNewWorld = false
                                    versionTapCount = 0
                                }
                            }
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
