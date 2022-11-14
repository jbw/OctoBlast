//
//  Color.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//

import SwiftUI

// https://stackoverflow.com/a/70851523

extension Color {
    /// Explicitly extracted Core Graphics color
    /// for the purpose of reconstruction and persistence.
    var cgColor_: CGColor { NSColor(self).cgColor }
}

extension UserDefaults {
    func setColor(_ color: Color, forKey key: String) {
        let cgColor: CGColor = color.cgColor_
        let array: [CGFloat] = cgColor.components ?? []
        set(array, forKey: key)
    }

    func color(forKey key: String) -> Color {
        guard let array: [CGFloat] = object(forKey: key) as? [CGFloat] else { return .accentColor }
        let color = CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: array)!
        return Color(color)
    }

    func setShowNotificationCount(_ showNotificationCount: Bool, forKey key: String) {
        set(showNotificationCount, forKey: key)
    }

    func notificationCount(forKey key: String) -> Bool {
        guard let showShowNotificationCount: Bool = object(forKey: key) as? Bool else { return false }

        return showShowNotificationCount
    }
}
