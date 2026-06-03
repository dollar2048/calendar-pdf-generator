import Foundation
import AppKit
import CoreGraphics
import CoreText

// Renders a 1024x1024 App Icon PNG to
// CalendarApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png

let size: CGFloat = 1024

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: r/255, green: g/255, blue: b/255, alpha: a)
}

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(
        data: nil,
        width: Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
    fputs("Failed to create context\n", stderr)
    exit(1)
}

let rect = CGRect(x: 0, y: 0, width: size, height: size)

// Background gradient (vibrant green → teal).
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        rgb(120, 200, 95).cgColor,
        rgb(60, 150, 130).cgColor
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

// Outer plant/leaf decoration along top + bottom corners.
func drawLeaf(at point: CGPoint, length: CGFloat, angle: CGFloat, color: NSColor) {
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
    ctx.setStrokeColor(rgb(82, 22, 46, 0.85).cgColor)
    ctx.setLineWidth(8)
    ctx.strokePath()
    ctx.restoreGState()
}

// Decorative leaves around the corners.
let leafColors: [NSColor] = [
    rgb(95, 180, 70), rgb(50, 140, 70), rgb(170, 215, 70), rgb(20, 110, 60)
]
let leafPositions: [(CGPoint, CGFloat, CGFloat)] = [
    (CGPoint(x: 80, y: size - 100), 240, .pi * 0.15),
    (CGPoint(x: 200, y: size - 60), 200, -.pi * 0.05),
    (CGPoint(x: size - 90, y: size - 120), 230, .pi * 0.95),
    (CGPoint(x: size - 240, y: size - 50), 210, .pi * 1.05),
    (CGPoint(x: 100, y: 160), 220, -.pi * 0.25),
    (CGPoint(x: size - 150, y: 200), 200, .pi * 1.25),
    (CGPoint(x: 60, y: 60), 180, .pi * 0.4),
]
for (i, item) in leafPositions.enumerated() {
    drawLeaf(at: item.0, length: item.1, angle: item.2, color: leafColors[i % leafColors.count])
}

// Berry clusters (red dots with outline).
func drawBerry(at p: CGPoint, radius: CGFloat) {
    let r = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
    ctx.setFillColor(rgb(230, 50, 50).cgColor)
    ctx.fillEllipse(in: r)
    ctx.setStrokeColor(rgb(82, 22, 46).cgColor)
    ctx.setLineWidth(6)
    ctx.strokeEllipse(in: r)
}
for p in [CGPoint(x: 250, y: size - 110), CGPoint(x: 280, y: size - 80),
          CGPoint(x: size - 270, y: size - 100), CGPoint(x: 130, y: 200)] {
    drawBerry(at: p, radius: 28)
}

// White rounded calendar card center.
let cardInset: CGFloat = 165
let cardRect = CGRect(x: cardInset, y: cardInset, width: size - cardInset * 2, height: size - cardInset * 2)
let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 60, cornerHeight: 60, transform: nil)
ctx.addPath(cardPath)
ctx.setFillColor(NSColor.white.cgColor)
ctx.fillPath()
ctx.addPath(cardPath)
ctx.setStrokeColor(rgb(82, 22, 46, 0.45).cgColor)
ctx.setLineWidth(8)
ctx.strokePath()

// Mini calendar grid: header strip + 5x7 (we use 4x4 simplified) cells.
let gridInset: CGFloat = 50
let gridRect = cardRect.insetBy(dx: gridInset, dy: gridInset)
let headerHeight: CGFloat = 70
let cols = 4
let rows = 4
let cellW = gridRect.width / CGFloat(cols)
let cellH = (gridRect.height - headerHeight) / CGFloat(rows)

ctx.setFillColor(rgb(60, 150, 130, 0.18).cgColor)
ctx.fill(CGRect(x: gridRect.minX, y: gridRect.maxY - headerHeight,
                width: gridRect.width, height: headerHeight))

ctx.setStrokeColor(rgb(82, 22, 46, 0.55).cgColor)
ctx.setLineWidth(4)
for c in 0...cols {
    let x = gridRect.minX + CGFloat(c) * cellW
    ctx.move(to: CGPoint(x: x, y: gridRect.minY))
    ctx.addLine(to: CGPoint(x: x, y: gridRect.maxY))
}
ctx.strokePath()
for r in 0...rows {
    let y = gridRect.minY + CGFloat(r) * cellH
    ctx.move(to: CGPoint(x: gridRect.minX, y: y))
    ctx.addLine(to: CGPoint(x: gridRect.maxX, y: y))
}
ctx.move(to: CGPoint(x: gridRect.minX, y: gridRect.maxY))
ctx.addLine(to: CGPoint(x: gridRect.maxX, y: gridRect.maxY))
ctx.move(to: CGPoint(x: gridRect.minX, y: gridRect.maxY - headerHeight))
ctx.addLine(to: CGPoint(x: gridRect.maxX, y: gridRect.maxY - headerHeight))
ctx.strokePath()

// Highlight last column (weekend) cells with light pink.
let weekendCol = cols - 1
let weekendX = gridRect.minX + CGFloat(weekendCol) * cellW
let weekendRect = CGRect(x: weekendX, y: gridRect.minY,
                         width: cellW, height: gridRect.height - headerHeight)
ctx.setFillColor(rgb(252, 230, 230).cgColor)
ctx.fill(weekendRect)
ctx.setStrokeColor(rgb(82, 22, 46, 0.55).cgColor)
ctx.setLineWidth(4)
ctx.stroke(weekendRect)
// Re-stroke vertical/horizontal lines after the fill.
for c in 0...cols {
    let x = gridRect.minX + CGFloat(c) * cellW
    ctx.move(to: CGPoint(x: x, y: gridRect.minY))
    ctx.addLine(to: CGPoint(x: x, y: gridRect.maxY))
}
for r in 0...rows {
    let y = gridRect.minY + CGFloat(r) * cellH
    ctx.move(to: CGPoint(x: gridRect.minX, y: y))
    ctx.addLine(to: CGPoint(x: gridRect.maxX, y: y))
}
ctx.move(to: CGPoint(x: gridRect.minX, y: gridRect.maxY - headerHeight))
ctx.addLine(to: CGPoint(x: gridRect.maxX, y: gridRect.maxY - headerHeight))
ctx.strokePath()

// Script "C" centered above the grid (in header strip area).
let titleText = "C"
let titleFont = NSFont(name: "SnellRoundhand-Black", size: 220)
    ?? NSFont(name: "SnellRoundhand-Bold", size: 220)
    ?? NSFont.systemFont(ofSize: 220, weight: .heavy)
let titleAttr = NSAttributedString(string: titleText, attributes: [
    .font: titleFont,
    .foregroundColor: NSColor.black
])
let line = CTLineCreateWithAttributedString(titleAttr as CFAttributedString)
var ascent: CGFloat = 0
var descent: CGFloat = 0
let titleWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
let headerCenterY = gridRect.maxY - headerHeight / 2
let baselineY = headerCenterY - (ascent - descent) / 2

// White halo behind the C.
let halo = CTLineCreateWithAttributedString(
    NSAttributedString(string: titleText, attributes: [
        .font: titleFont,
        .foregroundColor: NSColor.white,
        .strokeColor: NSColor.white,
        .strokeWidth: 28.0
    ]) as CFAttributedString
)
ctx.textPosition = CGPoint(x: (size - titleWidth) / 2, y: baselineY)
CTLineDraw(halo, ctx)
ctx.textPosition = CGPoint(x: (size - titleWidth) / 2, y: baselineY)
CTLineDraw(line, ctx)

guard let cgImage = ctx.makeImage() else {
    fputs("Failed to create image\n", stderr)
    exit(1)
}
let rep = NSBitmapImageRep(cgImage: cgImage)
guard let data = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

let outDir = "CalendarApp/Assets.xcassets/AppIcon.appiconset"
let outPath = "\(outDir)/AppIcon.png"
try data.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath)")
