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
    /// for the purpose of reconstruction and persistance.
    var cgColor_: CGColor {
        NSColor(self).cgColor
    }
}

extension UserDefaults {
    func setColor(_ color: Color, forKey key: String) {
        let cgColor = color.cgColor_
        let array = cgColor.components ?? []
        set(array, forKey: key)
    }

    func color(forKey key: String) -> Color {
        guard let array = object(forKey: key) as? [CGFloat] else {
            return .accentColor
        }
        let color = CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: array)!
        return Color(color)
    }
}
