//
// Created by Jason Watson on 09/09/2022.
// Copyright (c) 2022 JBW. All rights reserved.
//

import Foundation
import SwiftUI

struct AppearanceDetail: View {
    var refreshStatusIcon: () -> Void

    init(refreshStatusIcon: @escaping () -> Void) { self.refreshStatusIcon = refreshStatusIcon }

    @State private var iconColor: Color = UserDefaults.standard.color(forKey: "iconTint")

    @State private var showNotificationCount: Bool = UserDefaults.standard.notificationCount(forKey: "showNotificationCount")

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ColorPicker("Status icon color", selection: $iconColor, supportsOpacity: true)
                        .onChange(
                            of: iconColor,
                            perform: { newValue in
                                UserDefaults.standard.setColor(newValue, forKey: "iconTint")
                                refreshStatusIcon()
                            }
                        )

                    Button("Reset") {
                        UserDefaults.standard.setColor(.accentColor, forKey: "iconTint")
                        iconColor = .accentColor
                        refreshStatusIcon()
                    }
                }

                Toggle("Show notification count", isOn: $showNotificationCount)
                    .onChange(
                        of: showNotificationCount,
                        perform: { newValue in
                            UserDefaults.standard.setShowNotificationCount(newValue, forKey: "showNotificationCount")
                            refreshStatusIcon()
                        }
                    )

                Spacer()
            }
            .padding()
            Spacer()
        }
        .padding()
    }
}
