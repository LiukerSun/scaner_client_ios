//
//  scanerApp.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI

@main
struct scanerApp: App {
    @AppStorage("appMode") private var appMode: String = "anchor" // "anchor", "scanner", "admin"
    
    var body: some Scene {
        WindowGroup {
            switch appMode {
            case "admin":
                AdminRootView()
            case "scanner":
                ScannerRootView()
            case "anchor":
                AnchorRootView()
            default:
                ScannerRootView()
            }
        }
    }
}
