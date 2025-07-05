//
//  AnchorSettingsView.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI

struct AnchorSettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("关于软件")
                        }
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

struct AboutView: View {
    @AppStorage("appMode") private var appMode: String = "anchor"
    @State private var versionTapCount = 0
    
    var body: some View {
        List {
            Section(header: Text("信息")) {
                HStack {
                    Text("应用名称")
                    Spacer()
                    Text("海关查收货物管理系统")
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
                                appMode = "scanner"
                                versionTapCount = 0
                            }
                        }
                }
            }
        }
        .navigationTitle("关于软件")
        .navigationBarTitleDisplayMode(.inline)
    }
}
