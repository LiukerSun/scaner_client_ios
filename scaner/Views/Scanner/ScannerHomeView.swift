import SwiftUI
import UIKit

struct ScannerHomeView: View {
    @State private var isShowingScanner = false
    @State private var currentScanType: String = "normal"
    // 扫码记录
    @State private var scanRecords: [ScanRecord] = []
    @AppStorage("backendURL") private var backendURL: String = "http://192.168.50.128:5000"

    var body: some View {
        NavigationView {
            VStack {
                // 扫码记录列表
                List(scanRecords) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.code)
                                .font(.headline)
                            HStack(spacing: 8) {
                                Text(record.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                let labelColor: Color = record.scanType == "emergency" ? .red : .blue
                                Text(record.scanTypeDisplay)
                                    .font(.caption)
                                    .foregroundColor(labelColor)
                                    .padding(.horizontal, 4)
                                    .background(labelColor.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        Spacer()
                        Text(record.status.displayText)
                            .foregroundColor(record.status.color)
                    }
                }
                .listStyle(.plain)

                Spacer()

                // 底部按钮
                HStack(spacing: 16) {
                    // 普通扫码按钮
                    Button {
                        currentScanType = "normal"
                        isShowingScanner = true
                    } label: {
                        VStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 24))
                            Text("普通扫码")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }

                    // 加急扫码按钮
                    Button {
                        currentScanType = "emergency"
                        isShowingScanner = true
                    } label: {
                        VStack {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 24))
                            Text("加急扫码")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("扫码端")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        scanRecords.removeAll()
                    } label: {
                        Label("清空", systemImage: "trash")
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingScanner) {
                // 扫描视图
                BarcodeScannerView { code in
                    isShowingScanner = false
                    // 新增记录并开始上传
                    let record = ScanRecord(code: code, timestamp: Date(), status: .uploading, scanType: currentScanType)
                    scanRecords.insert(record, at: 0)

                    Task {
                        await sendScanRequest(code: code, recordID: record.id)
                    }
                } onCancel: {
                    isShowingScanner = false
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - 网络请求
    @MainActor
    private func sendScanRequest(code: String, recordID: UUID) async {
        guard let url = URL(string: "\(backendURL)/scan") else {
            updateRecord(id: recordID, status: .failed)
            return
        }

        let payload = ScanPayload(code: code,
                                   timestamp: Date().timeIntervalSince1970,
                                   device_info: UIDevice.current.model,
                                   type: currentScanType)

        guard let bodyData = try? JSONEncoder().encode(payload) else {
            updateRecord(id: recordID, status: .failed)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                updateRecord(id: recordID, status: .success)
            } else {
                updateRecord(id: recordID, status: .failed)
            }
        } catch {
            updateRecord(id: recordID, status: .failed)
        }
    }

    // 更新指定记录状态
    private func updateRecord(id: UUID, status: UploadStatus) {
        if let index = scanRecords.firstIndex(where: { $0.id == id }) {
            scanRecords[index].status = status
        }
    }
}

// MARK: - 请求体模型

// 上传状态
enum UploadStatus {
    case uploading
    case success
    case failed

    var displayText: String {
        switch self {
        case .uploading: return "上传中"
        case .success: return "成功"
        case .failed: return "失败"
        }
    }

    var color: Color {
        switch self {
        case .uploading: return .orange
        case .success: return .green
        case .failed: return .red
        }
    }
}

// 扫码记录模型
struct ScanRecord: Identifiable {
    let id: UUID
    let code: String
    let timestamp: Date
    var status: UploadStatus
    let scanType: String   // "normal" or "emergency"

    var scanTypeDisplay: String {
        scanType == "emergency" ? "加急" : "普通"
    }

    init(code: String, timestamp: Date, status: UploadStatus, scanType: String) {
        self.id = UUID()
        self.code = code
        self.timestamp = timestamp
        self.status = status
        self.scanType = scanType
    }
}

private struct ScanPayload: Codable {
    let code: String
    let timestamp: Double
    let device_info: String
    let type: String
}
