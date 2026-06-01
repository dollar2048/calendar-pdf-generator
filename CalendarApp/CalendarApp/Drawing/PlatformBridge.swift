import Foundation
import CoreGraphics

#if canImport(AppKit)
import AppKit
typealias UColor = NSColor
typealias UFont = NSFont
typealias UImage = NSImage
#else
import UIKit
typealias UColor = UIColor
typealias UFont = UIFont
typealias UImage = UIImage
#endif

extension UColor {
    static func rgb255(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> UColor {
        UColor(red: r/255, green: g/255, blue: b/255, alpha: a)
    }
}

enum PlatformGraphics {
    static func pushCGContext(_ ctx: CGContext) {
        #if canImport(AppKit)
        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx
        #else
        UIGraphicsPushContext(ctx)
        #endif
    }

    static func popCGContext() {
        #if canImport(AppKit)
        NSGraphicsContext.restoreGraphicsState()
        #else
        UIGraphicsPopContext()
        #endif
    }
}

extension UImage {
    func cgImageRepresentation() -> CGImage? {
        #if canImport(AppKit)
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #else
        return cgImage
        #endif
    }
}
