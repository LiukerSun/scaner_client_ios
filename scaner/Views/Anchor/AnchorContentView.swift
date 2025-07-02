//
//  ContentView.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI

struct AnchorContentView: View {
    var body: some View {
        TabView {
            // 首页
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
            
            // 设置页面
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
        }
    }
}
