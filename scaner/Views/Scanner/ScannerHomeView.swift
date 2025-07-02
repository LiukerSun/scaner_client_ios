import SwiftUI

struct ScannerHomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Image(systemName: "globe")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.purple)
                Text("欢迎来到扫码端！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("这里是完全不同的界面和体验。")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("扫码端")
        }
    }
}
