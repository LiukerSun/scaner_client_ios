//
//  scanerApp.swift
//  scaner
//
//  Created by Evan on 2025/6/30.
//

import SwiftUI

@main
struct scanerApp: App {
    @AppStorage("isNewWorld") private var isNewWorld: Bool = false
    var body: some Scene {
        WindowGroup {
            if isNewWorld {
                ScannerRootView()
            } else {
                AnchorContentView()
            }
        }
    }
}
