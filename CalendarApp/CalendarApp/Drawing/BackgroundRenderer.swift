import Foundation
import CoreGraphics

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

enum BackgroundRenderer {
    static let pageWidth: CGFloat = 841.89
    static let pageHeight: CGFloat = 595.28

    private struct SeededRNG: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed == 0 ? 0xDEADBEEF : seed }
        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    private static func randUnit(_ rng: inout SeededRNG) -> CGFloat {
        CGFloat(rng.next() % 10_000) / 10_000.0
    }

    private static func randRange(_ rng: inout SeededRNG, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        lo + randUnit(&rng) * (hi - lo)
    }

    private static func pick<T>(_ array: [T], _ rng: inout SeededRNG) -> T {
        array[Int(rng.next() % UInt64(array.count))]
    }

    private enum Edge { case top, bottom, left, right }

    private static func placeOnBorder(edge: Edge, t: CGFloat, depth: CGFloat) -> CGPoint {
        switch edge {
        case .top:    return CGPoint(x: t * pageWidth, y: pageHeight - depth)
        case .bottom: return CGPoint(x: t * pageWidth, y: depth)
        case .left:   return CGPoint(x: depth, y: t * pageHeight)
        case .right:  return CGPoint(x: pageWidth - depth, y: t * pageHeight)
        }
    }

    private static let outlineColor: UColor = .rgb255(82, 22, 46, 0.85)

    private static func drawLeaf(at point: CGPoint, length: CGFloat, angle: CGFloat, color: UColor, in ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: point.x, y: point.y)
        ctx.rotate(by: angle)

        let width = length * 0.45
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addCurve(to: CGPoint(x: length, y: 0),
                      control1: CGPoint(x: length * 0.3, y: width),
                      control2: CGPoint(x: length * 0.7, y: width))
        path.addCurve(to: .zero,
                      control1: CGPoint(x: length * 0.7, y: -width),
                      control2: CGPoint(x: length * 0.3, y: -width))
        path.closeSubpath()

        ctx.addPath(path)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()

        ctx.addPath(path)
        ctx.setStrokeColor(outlineColor.cgColor)
        ctx.setLineWidth(1.6)
        ctx.strokePath()

        ctx.move(to: .zero)
        ctx.addLine(to: CGPoint(x: length, y: 0))
        ctx.setStrokeColor(UColor.rgb255(82, 22, 46, 0.65).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokePath()

        let sideVeinCount = 3
        ctx.setStrokeColor(UColor.rgb255(82, 22, 46, 0.45).cgColor)
        ctx.setLineWidth(0.7)
        for k in 1...sideVeinCount {
            let t = CGFloat(k) / CGFloat(sideVeinCount + 1)
            let baseX = length * t
            let span = (length * 0.45) * (1 - abs(t - 0.5) * 1.3)
            ctx.move(to: CGPoint(x: baseX, y: 0))
            ctx.addLine(to: CGPoint(x: baseX + span * 0.4, y: span))
            ctx.move(to: CGPoint(x: baseX, y: 0))
            ctx.addLine(to: CGPoint(x: baseX + span * 0.4, y: -span))
        }
        ctx.strokePath()

        ctx.restoreGState()
    }

    private static func drawFlower(at point: CGPoint, radius: CGFloat, petals: Int, color: UColor, centerColor: UColor, in ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: point.x, y: point.y)

        for i in 0..<petals {
            let angle = (CGFloat.pi * 2 / CGFloat(petals)) * CGFloat(i)
            let pw = radius * 0.55
            let tipX = cos(angle) * radius
            let tipY = sin(angle) * radius
            let leftX = cos(angle + .pi/2) * pw * 0.5
            let leftY = sin(angle + .pi/2) * pw * 0.5
            let rightX = cos(angle - .pi/2) * pw * 0.5
            let rightY = sin(angle - .pi/2) * pw * 0.5

            let path = CGMutablePath()
            path.move(to: .zero)
            path.addCurve(to: CGPoint(x: tipX, y: tipY),
                          control1: CGPoint(x: leftX, y: leftY),
                          control2: CGPoint(x: tipX + leftX * 0.4, y: tipY + leftY * 0.4))
            path.addCurve(to: .zero,
                          control1: CGPoint(x: tipX + rightX * 0.4, y: tipY + rightY * 0.4),
                          control2: CGPoint(x: rightX, y: rightY))
            path.closeSubpath()

            ctx.addPath(path)
            ctx.setFillColor(color.cgColor)
            ctx.fillPath()

            ctx.addPath(path)
            ctx.setStrokeColor(outlineColor.cgColor)
            ctx.setLineWidth(1.3)
            ctx.strokePath()
        }

        let centerRect = CGRect(x: -radius * 0.25, y: -radius * 0.25, width: radius * 0.5, height: radius * 0.5)
        ctx.setFillColor(centerColor.cgColor)
        ctx.fillEllipse(in: centerRect)
        ctx.setStrokeColor(UColor.rgb255(82, 22, 46, 0.9).cgColor)
        ctx.setLineWidth(1.3)
        ctx.strokeEllipse(in: centerRect)

        ctx.restoreGState()
    }

    private static func drawBerryCluster(at point: CGPoint, radius: CGFloat, count: Int, color: UColor, in ctx: CGContext, rng: inout SeededRNG) {
        for _ in 0..<count {
            let dx = randRange(&rng, -radius * 1.4, radius * 1.4)
            let dy = randRange(&rng, -radius * 1.4, radius * 1.4)
            let r = radius * randRange(&rng, 0.7, 1.1)
            let circleRect = CGRect(x: point.x + dx - r, y: point.y + dy - r, width: r * 2, height: r * 2)
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: circleRect)
            ctx.setStrokeColor(UColor.rgb255(82, 22, 46, 0.9).cgColor)
            ctx.setLineWidth(1.1)
            ctx.strokeEllipse(in: circleRect)

            let highlight = CGRect(x: point.x + dx - r * 0.35, y: point.y + dy - r * 0.05, width: r * 0.4, height: r * 0.4)
            ctx.setFillColor(UColor(white: 1, alpha: 0.5).cgColor)
            ctx.fillEllipse(in: highlight)
        }
    }

    private static func drawStem(from start: CGPoint, to end: CGPoint, control: CGPoint, color: UColor, in ctx: CGContext) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)

        ctx.addPath(path)
        ctx.setStrokeColor(UColor.rgb255(82, 22, 46, 0.7).cgColor)
        ctx.setLineWidth(2.6)
        ctx.setLineCap(.round)
        ctx.strokePath()

        ctx.addPath(path)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(2.0)
        ctx.setLineCap(.round)
        ctx.strokePath()
    }

    /// Renders the procedural floral border. `variation` re-rolls the layout:
    /// variation 0 reproduces the original fixed arrangement for each palette,
    /// higher values shuffle stems/flowers/berries while keeping the palette colors.
    // MARK: - Winter snow scene

    private static func drawSnowflake(at p: CGPoint, radius: CGFloat, rotation: CGFloat, color: UColor, in ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: p.x, y: p.y)
        ctx.rotate(by: rotation)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(max(1.1, radius * 0.10))
        ctx.setLineCap(.round)

        for i in 0..<6 {
            let a = CGFloat(i) * .pi / 3
            let tip = CGPoint(x: cos(a) * radius, y: sin(a) * radius)
            ctx.move(to: .zero)
            ctx.addLine(to: tip)

            let b1 = a + .pi / 6
            let b2 = a - .pi / 6
            // Inner pair of branches.
            let inner = CGPoint(x: cos(a) * radius * 0.55, y: sin(a) * radius * 0.55)
            let innerLen = radius * 0.32
            ctx.move(to: inner)
            ctx.addLine(to: CGPoint(x: inner.x + cos(b1) * innerLen, y: inner.y + sin(b1) * innerLen))
            ctx.move(to: inner)
            ctx.addLine(to: CGPoint(x: inner.x + cos(b2) * innerLen, y: inner.y + sin(b2) * innerLen))
            // Outer pair of branches.
            let outer = CGPoint(x: cos(a) * radius * 0.8, y: sin(a) * radius * 0.8)
            let outerLen = radius * 0.22
            ctx.move(to: outer)
            ctx.addLine(to: CGPoint(x: outer.x + cos(b1) * outerLen, y: outer.y + sin(b1) * outerLen))
            ctx.move(to: outer)
            ctx.addLine(to: CGPoint(x: outer.x + cos(b2) * outerLen, y: outer.y + sin(b2) * outerLen))
        }
        ctx.strokePath()

        let centerR = radius * 0.13
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(x: -centerR, y: -centerR, width: centerR * 2, height: centerR * 2))
        ctx.restoreGState()
    }

    private static func renderSnow(palette: Palette, into ctx: CGContext, rect: CGRect, rng: inout SeededRNG) {
        // Pale icy wash so white snow reads; the opaque grid covers the center.
        ctx.setFillColor(UColor.rgb255(226, 238, 248).cgColor)
        ctx.fill(rect)

        let flakeColors = palette.flowerColors + palette.accentColors
        let edges: [Edge] = [.top, .bottom, .left, .right]
        let borderDepthMax: CGFloat = 155

        // Crystalline snowflakes clustered along the borders.
        for edge in edges {
            let count = Int(randRange(&rng, 14, 22))
            for _ in 0..<count {
                let t = randUnit(&rng)
                let depth = randRange(&rng, 10, borderDepthMax)
                let pos = placeOnBorder(edge: edge, t: t, depth: depth)
                drawSnowflake(
                    at: pos,
                    radius: randRange(&rng, 9, 26),
                    rotation: randRange(&rng, 0, .pi),
                    color: pick(flakeColors, &rng),
                    in: ctx
                )
            }
        }

        // Fine falling snow scattered across the whole page.
        let dots = 320
        for _ in 0..<dots {
            let x = randRange(&rng, 0, pageWidth)
            let y = randRange(&rng, 0, pageHeight)
            let r = randRange(&rng, 0.8, 2.8)
            let alpha = randRange(&rng, 0.55, 1.0)
            ctx.setFillColor(UColor(white: 1, alpha: alpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
    }

    static func render(palette: Palette, variation: Int = 0, into ctx: CGContext, rect: CGRect) {
        let baseSeed = UInt64(abs(palette.id.hashValue)) | 1
        let seed = baseSeed &+ UInt64(bitPattern: Int64(variation)) &* 7919
        var rng = SeededRNG(seed: seed)

        ctx.saveGState()
        ctx.setFillColor(UColor.white.cgColor)
        ctx.fill(rect)
        ctx.restoreGState()

        // Winter is a snow scene rather than a floral border.
        if palette.id == "winter" {
            renderSnow(palette: palette, into: ctx, rect: rect, rng: &rng)
            return
        }

        let edges: [Edge] = [.top, .bottom, .left, .right]
        let borderDepthMax: CGFloat = 140

        // Pass 1: stems + leaves.
        for edge in edges {
            let segments = 26
            for i in 0..<segments {
                let t = CGFloat(i) / CGFloat(segments) + randRange(&rng, -0.02, 0.02)
                let depth = randRange(&rng, 8, borderDepthMax)
                let anchor = placeOnBorder(edge: edge, t: max(0, min(1, t)), depth: depth)

                let inward: CGVector
                switch edge {
                case .top: inward = CGVector(dx: 0, dy: -1)
                case .bottom: inward = CGVector(dx: 0, dy: 1)
                case .left: inward = CGVector(dx: 1, dy: 0)
                case .right: inward = CGVector(dx: -1, dy: 0)
                }

                let length = randRange(&rng, 40, 130)
                let tip = CGPoint(x: anchor.x + inward.dx * length, y: anchor.y + inward.dy * length)
                let curve = randRange(&rng, -35, 35)
                let perp = CGVector(dx: inward.dy, dy: -inward.dx)
                let control = CGPoint(x: (anchor.x + tip.x)/2 + perp.dx * curve, y: (anchor.y + tip.y)/2 + perp.dy * curve)
                drawStem(from: anchor, to: tip, control: control, color: pick(palette.leafColors, &rng), in: ctx)

                let leafCount = Int(randRange(&rng, 2, 5))
                for j in 0..<leafCount {
                    let s = CGFloat(j + 1) / CGFloat(leafCount + 1)
                    let pos = CGPoint(x: anchor.x + (tip.x - anchor.x) * s, y: anchor.y + (tip.y - anchor.y) * s)
                    let leafLen = randRange(&rng, 36, 95)
                    let leafAngle = atan2(inward.dy, inward.dx) + randRange(&rng, -1.3, 1.3)
                    drawLeaf(at: pos, length: leafLen, angle: leafAngle, color: pick(palette.leafColors, &rng), in: ctx)
                }
            }
        }

        // Pass 2: flowers + berries.
        for edge in edges {
            let bursts = Int(randRange(&rng, 10, 18))
            for _ in 0..<bursts {
                let t = randUnit(&rng)
                let depth = randRange(&rng, 15, borderDepthMax - 10)
                let pos = placeOnBorder(edge: edge, t: t, depth: depth)
                let kind = rng.next() % 3
                switch kind {
                case 0:
                    drawFlower(
                        at: pos,
                        radius: randRange(&rng, 18, 36),
                        petals: [5, 6, 8, 10].randomElement(using: &rng) ?? 5,
                        color: pick(palette.flowerColors, &rng),
                        centerColor: pick(palette.accentColors, &rng),
                        in: ctx
                    )
                case 1:
                    drawBerryCluster(
                        at: pos,
                        radius: randRange(&rng, 6, 11),
                        count: Int(randRange(&rng, 4, 9)),
                        color: pick(palette.berryColors, &rng),
                        in: ctx,
                        rng: &rng
                    )
                default:
                    drawFlower(
                        at: pos,
                        radius: randRange(&rng, 8, 14),
                        petals: 5,
                        color: pick(palette.accentColors, &rng),
                        centerColor: pick(palette.flowerColors, &rng),
                        in: ctx
                    )
                }
            }
        }
    }
}
