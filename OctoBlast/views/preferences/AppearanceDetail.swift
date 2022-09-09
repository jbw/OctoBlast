//
// Created by Jason Watson on 09/09/2022.
// Copyright (c) 2022 JBW. All rights reserved.
//

import Foundation
import SwiftUI

struct AppearanceDetail: View {
    var refreshStatusIcon: () -> Void

    init(refreshStatusIcon: @escaping () -> Void) {
        self.refreshStatusIcon = refreshStatusIcon
    }

    @State private var iconColor: Color = UserDefaults.standard.color(forKey: "iconTint")

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                ColorPicker("Status icon color: ", selection: $iconColor, supportsOpacity: true)
                    .onChange(
                        of: iconColor,
                        perform: { newValue in
                            UserDefaults.standard.setColor(newValue, forKey: "iconTint")
                            self.refreshStatusIcon()

                        }
                    )

                Button("Reset") {
                    UserDefaults.standard.setColor(.accentColor, forKey: "iconTint")
                    iconColor = .accentColor
                    self.refreshStatusIcon()
                }
                Spacer()
            }
            .padding()
            Spacer()
        }
        .padding()
    }
}
