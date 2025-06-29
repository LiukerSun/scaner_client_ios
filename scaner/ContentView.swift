//
//  ContentView.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI
import AVFoundation

// 扫码记录结构
struct ScanRecord: Identifiable {
    let id = UUID()
    let code: String
    let timestamp: Date
    let isSuccess: Bool
}

struct ContentView: View {
    @State private var showingScanner = false
    @State private var showingSettings = false
    @State private var scannedCode = ""
    @State private var isSending = false
    @State private var scanCount = 0
    @State private var scanHistory: [ScanRecord] = []
    @State private var lastScannedCode = ""
    @State private var lastScanTime = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                // 标题和统计
                HStack {
                    Text("扫码器")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Text("已扫描: \(scanCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // 扫码历史记录
                if !scanHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("扫码历史:")
                                .font(.headline)
                            Spacer()
                            if isSending {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                    Text("发送中...")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(scanHistory) { record in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(record.code)
                                                .font(.body)
                                                .lineLimit(2)
                                            Text(formatDate(record.timestamp))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        if record.isSuccess {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal)
                }
                
                // 扫码按钮
                Button(action: {
                    showingScanner = true
                }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.title2)
                        Text("开始扫描")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isSending)
                .padding(.horizontal)
                
                // 清空历史按钮
                if !scanHistory.isEmpty {
                    Button(action: {
                        scanHistory.removeAll()
                        scanCount = 0
                        lastScannedCode = ""
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清空历史")
                        }
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                    }
                }
                
                // 设置按钮
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("设置接口地址")
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingScanner) {
                CodeScannerView(codeTypes: [.qr, .code128, .code39, .ean13, .ean8, .upce, .code93, .pdf417, .aztec]) { result in
                    switch result {
                    case .success(let code):
                        // 防重复扫码：检查是否与上次扫码相同且在2秒内
                        let currentTime = Date()
                        let timeInterval = currentTime.timeIntervalSince(lastScanTime)
                        
                        if code == lastScannedCode && timeInterval < 2.0 {
                            print("检测到重复扫码，已忽略: \(code)")
                            return
                        }
                        
                        scannedCode = code
                        scanCount += 1
                        lastScannedCode = code
                        lastScanTime = currentTime
                        showingScanner = false
                        
                        // 添加到历史记录
                        let newRecord = ScanRecord(code: code, timestamp: currentTime, isSuccess: false)
                        scanHistory.insert(newRecord, at: 0) // 最新记录放在最前面
                        
                        // 自动发送，不显示弹窗
                        sendScannedCodeSilently(code: code, record: newRecord)
                        
                    case .failure(let error):
                        // 扫描失败时显示简单提示
                        print("扫描失败: \(error.localizedDescription)")
                        showingScanner = false
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func sendScannedCodeSilently(code: String, record: ScanRecord) {
        guard let apiUrl = UserDefaults.standard.string(forKey: "apiUrl"), !apiUrl.isEmpty else {
            print("未配置接口地址")
            // 更新记录状态为失败
            if let index = scanHistory.firstIndex(where: { $0.id == record.id }) {
                scanHistory[index] = ScanRecord(code: code, timestamp: record.timestamp, isSuccess: false)
            }
            return
        }
        
        isSending = true
        
        sendCodeToServer(code: code, apiUrl: apiUrl) { success, message in
            DispatchQueue.main.async {
                isSending = false
                if !success {
                    print("发送失败: \(message)")
                }
                
                // 更新记录状态
                if let index = scanHistory.firstIndex(where: { $0.id == record.id }) {
                    scanHistory[index] = ScanRecord(code: code, timestamp: record.timestamp, isSuccess: success)
                }
            }
        }
    }
    
    private func sendCodeToServer(code: String, apiUrl: String, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: apiUrl) else {
            completion(false, "无效的接口地址")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "code": code,
            "timestamp": Date().timeIntervalSince1970,
            "device_info": "iOS Device"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(false, "数据序列化失败")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "网络请求失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true, "发送成功")
                    } else {
                        completion(false, "服务器响应错误: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "未知响应")
                }
            }
        }.resume()
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var apiUrl = UserDefaults.standard.string(forKey: "apiUrl") ?? ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("服务器设置")) {
                    TextField("接口地址", text: $apiUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                    
                    Text("请输入完整的HTTP/HTTPS接口地址")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("示例")) {
                    Text("https://api.example.com/scan")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("手动扫码模式")) {
                    Text("• 点击 开始扫描 按钮启动相机")
                    Text("• 扫码后自动发送到服务器")
                    Text("• 扫码完成后返回主界面")
                    Text("• 需要再次扫码时重新点击按钮")
                    Text("• 扫码历史按时间倒序显示")
                    Text("• 防重复扫码机制（2秒内相同条码忽略）")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    UserDefaults.standard.set(apiUrl, forKey: "apiUrl")
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// 简单的扫码视图
struct CodeScannerView: UIViewControllerRepresentable {
    let codeTypes: [AVMetadataObject.ObjectType]
    let completion: (Result<String, ScanError>) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.codeTypes = codeTypes
        viewController.completion = completion
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var codeTypes: [AVMetadataObject.ObjectType] = []
    var completion: ((Result<String, ScanError>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            completion?(.failure(.deviceNotFound))
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            completion?(.failure(.inputError))
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            completion?(.failure(.inputError))
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = codeTypes
        } else {
            completion?(.failure(.outputError))
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            completion?(.success(stringValue))
        }
    }
}

enum ScanError: Error {
    case deviceNotFound
    case inputError
    case outputError
    
    var localizedDescription: String {
        switch self {
        case .deviceNotFound:
            return "无法访问相机"
        case .inputError:
            return "相机输入错误"
        case .outputError:
            return "相机输出错误"
        }
    }
}

#Preview {
    ContentView()
}
