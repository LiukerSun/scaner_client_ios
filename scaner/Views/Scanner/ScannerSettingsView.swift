//
//  ScannerSettingsView.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI

struct ScannerSettingsView: View {
  @AppStorage("backendURL") private var backendURL: String = "http://192.168.50.128:5000"
  @AppStorage("scannerTorchOn") private var scannerTorchOn: Bool = false

  var body: some View {
    NavigationView {
      List {
        Section(header: Text("网络设置")) {
          NavigationLink(destination: BackendURLSettingsView()) {
            HStack {
              Text("后端地址")
              Spacer()
              Text(backendURL)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
            }
          }
        }
        Section(header: Text("扫描设置")) {
          Toggle("扫码时开启闪光灯", isOn: $scannerTorchOn)
        }
        Section {
          NavigationLink(destination: ScannerAboutView()) {
            HStack {
              Image(systemName: "info.circle")
                .foregroundColor(.blue)
              Text("关于系统")
            }
          }
        }
      }
      .navigationTitle("设置")
    }
  }
}

struct BackendURLSettingsView: View {
  @AppStorage("backendURL") private var backendURL: String = "http://192.168.50.128:5000"

  var body: some View {
    Form {
      Section(header: Text("后端地址")) {
        TextField("请输入后端地址", text: $backendURL)
          .autocapitalization(.none)
          .keyboardType(.URL)
      }
    }
    .navigationTitle("后端地址")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct ScannerAboutView: View {
  @AppStorage("appMode") private var appMode: String = "scanner"
  @State private var versionTapCount = 0

  var body: some View {
    List {
      Section(header: Text("信息")) {
        HStack {
          Text("应用名称")
          Spacer()
          Text("扫码端")
            .foregroundColor(.gray)
            .onTapGesture {
              versionTapCount += 1
              if versionTapCount >= 5 {
                appMode = "admin"
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
                appMode = "anchor"
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
