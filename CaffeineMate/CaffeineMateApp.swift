//
//  CaffeineMateApp.swift
//  CaffeineMate
//
//  Created by Edd on 07/10/2025.
//

import SwiftUI

@main
struct CaffeineMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
