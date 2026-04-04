//
//  ColorToHex.swift
//  SVLBH Panel — extension toHex importée de Palette de Lumière
//

import SwiftUI

extension Color {
    func toHex(includeAlpha: Bool = false) -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r: CGFloat = components.count >= 1 ? components[0] : 0
        let g: CGFloat = components.count >= 2 ? components[1] : 0
        let b: CGFloat = components.count >= 3 ? components[2] : 0
        let a: CGFloat = components.count >= 4 ? components[3] : 1
        if includeAlpha {
            return String(format: "#%02lX%02lX%02lX%02lX",
                lround(Double(r * 255)), lround(Double(g * 255)),
                lround(Double(b * 255)), lround(Double(a * 255)))
        } else {
            return String(format: "#%02lX%02lX%02lX",
                lround(Double(r * 255)), lround(Double(g * 255)),
                lround(Double(b * 255)))
        }
    }
}
