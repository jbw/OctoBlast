//
//  OctoBlastApp.swift
//  OctoBlast
//
//  Created by Jason Watson on 07/08/2022.
//

import SwiftUI

@main
struct OctoBlastApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
