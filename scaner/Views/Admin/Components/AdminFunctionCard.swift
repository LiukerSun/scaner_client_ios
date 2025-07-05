import SwiftUI

struct AdminFunctionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct AdminFunctionCard_Previews: PreviewProvider {
    static var previews: some View {
        AdminFunctionCard(
            title: "商品管理",
            subtitle: "管理商品信息",
            icon: "cube.box",
            color: .blue
        ) {
            // 示例动作
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 