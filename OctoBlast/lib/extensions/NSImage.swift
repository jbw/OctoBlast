//
//  NSImage.swift
//  OctoBlast
//
//  Created by Jason Watson on 16/08/2022.
//

import SwiftUI

// https://stackoverflow.com/a/50074538
extension NSImage {
    func tint(color: NSColor) -> NSImage {
        let image = copy() as! NSImage
        image.lockFocus()

        color.set()

        let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
        imageRect.fill(using: .sourceAtop)

        image.unlockFocus()

        return image
    }
}
