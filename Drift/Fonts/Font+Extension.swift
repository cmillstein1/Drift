//
//  Font+Extension.swift
//  Drift
//
//  Created by Casey Millstein on 1/16/26.
//


import SwiftUI

extension Font {
    static func campfire(_ weight: Campfire, size: CGFloat) -> Font {
        let fontName = weight.fontName
        return Font.custom(fontName, size: size)
    }
    
    enum Campfire {
        case regular
        
        
        var fontName: String {
            switch self{
            case .regular: return "Campfire"
            }
        }
    }
}
