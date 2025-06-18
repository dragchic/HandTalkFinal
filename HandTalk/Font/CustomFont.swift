//
//  CustomFont.swift
//  HandTalk
//
//  Created by William on 18/06/25.
//
import SwiftUI

enum ShantellSans {
    case regular
    case medium
    case bold
    
    var fontName: String {
        switch self {
        case .regular:
            return "ShantellSans-Regular"
        case .medium:
            return "ShantellSans-Medium"
        case .bold:
            return "ShantellSans-Bold"
        }
    }
}

struct ShantellSansTextModifier: ViewModifier {
    
    let weight : ShantellSans
    let size : CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.custom(weight.fontName, size: size))
            .foregroundColor(.black)
    }
}

extension View {
    func ShantellSans(weight : ShantellSans,size: CGFloat) -> some View {
        self.modifier(ShantellSansTextModifier(weight: weight, size: size))
    }
}
