//
//  AnchorRootView.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI

struct AnchorRootView: View {
    var body: some View {
        TabView {
            AnchorHomeView()
                .tabItem {
                    VStack {
                        Image(systemName: "house")
                            .font(.system(size: 22))
                        Text("首页")
                            .font(.system(size: 15, weight: .medium))
                    }
                }

            AnchorSettingsView()
                .tabItem {
                    VStack {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22))
                        Text("设置")
                            .font(.system(size: 15, weight: .medium))
                    }
                }
        }
        .navigationTitle("海关查收货物管理系统")
    }
}
