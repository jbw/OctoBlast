//
// Created by Jason Watson on 09/09/2022.
// Copyright (c) 2022 JBW. All rights reserved.
//

import Foundation
import LaunchAtLogin
import SwiftUI

struct AboutDetail: View {
    @StateObject var updaterViewModel = UpdaterViewModel()
    @State private var hover: Bool = false
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()

            Text("OctoBlast").font(.system(.title, design: .rounded))

            Image(nsImage: NSImage(named: NSImage.Name("AppIcon"))!)

            Text("[@jasonwatson](https://twitter.com/jasonwatson) (Jason Watson)")
                .font(.system(.body, design: .rounded))
                .onHover { isHovered in
                    self.hover = isHovered
                    DispatchQueue.main.async {
                        if self.hover {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }

            Text("[https://octoblast.jbw.codes](https://octoblast.jbw.codes)")
                .onHover { isHovered in
                    self.hover = isHovered
                    DispatchQueue.main.async {
                        if self.hover {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }

            let versionLocation: URL? = Bundle.main.url(
                forResource: "version",
                withExtension: "txt"
            )

            if versionLocation != nil {
                let version: String? = try? String(contentsOf: versionLocation!)
                Text(version ?? "")
            }

            LaunchAtLogin.Toggle { Text("Launch at login") }

            CheckForUpdatesView(updaterViewModel: updaterViewModel)

            Spacer()
        }
    }
}
