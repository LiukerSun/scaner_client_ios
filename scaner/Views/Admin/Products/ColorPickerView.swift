import SwiftUI

// MARK: - Color Picker View
struct ColorPickerView: View {
    let availableColors: [ProductColor]
    @Binding var selectedColors: Set<Int>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                                
                if !selectedColors.isEmpty {
                    Section {
                        Text("已选择 \(selectedColors.count) 种颜色")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    } header: {
                        Text("选择状态")
                    }
                }
                Section {
                    Text("选择您需要的颜色（可多选）")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("颜色选择")
                }
                
                Section {
                    ForEach(availableColors) { color in
                        colorRow(color)
                    }
                } header: {
                    Text("可用颜色 (\(availableColors.count))")
                }

            }
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func colorRow(_ color: ProductColor) -> some View {
        let isSelected = selectedColors.contains(color.id)
        
        return Button(action: {
            if isSelected {
                selectedColors.remove(color.id)
            } else {
                selectedColors.insert(color.id)
            }
        }) {
            HStack(spacing: 12) {
                // 颜色块
                Rectangle()
                    .fill(colorFromHex(color.hexColor) ?? Color.gray)
                    .frame(width: 30, height: 30)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(color.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let code = color.code {
                        Text(code)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorFromHex(_ hex: String?) -> Color? {
        guard let hex = hex else { return nil }
        
        let cleanHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleanHex.count == 6 else { return nil }
        
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        
        let red = Double((int >> 16) & 0xFF) / 255.0
        let green = Double((int >> 8) & 0xFF) / 255.0
        let blue = Double(int & 0xFF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
} 