import Foundation
import CoreGraphics
import CoreText

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

enum CalendarPDFRenderer {
    static let pageWidth = BackgroundRenderer.pageWidth
    static let pageHeight = BackgroundRenderer.pageHeight

    static func renderPDFData(spec: CalendarSpec, background: CalendarBackground) -> Data? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData) else { return nil }
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        context.beginPDFPage(nil)
        context.setFillColor(UColor.white.cgColor)
        context.fill(mediaBox)

        drawBackground(background, into: context, rect: mediaBox)

        drawTitleAndGrid(spec: spec, in: context)

        context.endPDFPage()
        context.closePDF()
        return pdfData as Data
    }

    /// Draws the chosen background: procedural palette border, or a user image
    /// scaled to fill the page (aspect-fill, centered, clipped to the page).
    private static func drawBackground(_ background: CalendarBackground, into ctx: CGContext, rect: CGRect) {
        switch background {
        case let .palette(palette, variation):
            BackgroundRenderer.render(palette: palette, variation: variation, into: ctx, rect: rect)
        case let .custom(custom):
            drawAspectFill(custom.image, into: ctx, rect: rect)
        }
    }

    private static func drawAspectFill(_ image: CGImage, into ctx: CGContext, rect: CGRect) {
        ctx.saveGState()
        ctx.setFillColor(UColor.white.cgColor)
        ctx.fill(rect)

        let iw = CGFloat(image.width)
        let ih = CGFloat(image.height)
        guard iw > 0, ih > 0 else { ctx.restoreGState(); return }

        let scale = max(rect.width / iw, rect.height / ih)
        let drawSize = CGSize(width: iw * scale, height: ih * scale)
        let drawRect = CGRect(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        ctx.clip(to: rect)
        ctx.draw(image, in: drawRect)
        ctx.restoreGState()
    }

    static func renderPreviewImage(spec: CalendarSpec, background: CalendarBackground, scale: CGFloat = 1.5) -> CGImage? {
        let width = Int(pageWidth * scale)
        let height = Int(pageHeight * scale)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.scaleBy(x: scale, y: scale)
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        ctx.setFillColor(UColor.white.cgColor)
        ctx.fill(pageRect)
        drawBackground(background, into: ctx, rect: pageRect)
        drawTitleAndGrid(spec: spec, in: ctx)

        return ctx.makeImage()
    }

    private static func drawTitleAndGrid(spec: CalendarSpec, in context: CGContext) {
        let calendar = Calendar(identifier: .gregorian)
        let monthDate = calendar.date(from: DateComponents(year: spec.year, month: spec.month, day: 1))!
        let monthRange = calendar.range(of: .day, in: .month, for: monthDate)!
        let firstWeekday = calendar.component(.weekday, from: monthDate)
        let mondayBasedOffset = (firstWeekday + 5) % 7
        let totalCells = mondayBasedOffset + monthRange.count
        let rows = Int(ceil(Double(totalCells) / 7.0))

        let outerMargin: CGFloat = 36
        let weekdayHeaderHeight: CGFloat = 32
        let spacingAfterTitle: CGFloat = 8

        let monthFont = UFont(name: "SnellRoundhand-Black", size: 96)
            ?? UFont(name: "SnellRoundhand-Bold", size: 96)
            ?? UFont(name: "Zapfino", size: 70)
            ?? UFont(name: "Apple Chancery", size: 86)
            ?? UFont.systemFont(ofSize: 86, weight: .medium)
        let yearFont = UFont(name: "Didot", size: 38)
            ?? UFont(name: "Didot-Italic", size: 38)
            ?? UFont(name: "TimesNewRomanPS-ItalicMT", size: 38)
            ?? UFont.systemFont(ofSize: 38, weight: .regular)

        let monthAscent = monthFont.ascender
        let monthDescent = abs(monthFont.descender)
        let titleTotalHeight = monthAscent + monthDescent

        let gridTop = outerMargin + titleTotalHeight + spacingAfterTitle
        let gridHeight = pageHeight - gridTop - outerMargin
        let cellWidth = (pageWidth - (outerMargin * 2)) / 7.0
        let cellHeight = (gridHeight - weekdayHeaderHeight) / CGFloat(rows)

        let monthAttr = NSMutableAttributedString(string: spec.monthName.lowercased(), attributes: [
            .font: monthFont,
            .kern: 0.5
        ])
        monthAttr.append(NSAttributedString(string: "  \(spec.year)", attributes: [
            .font: yearFont,
            .baselineOffset: 22.0,
            .kern: 0.8
        ]))

        let titleLineHalo = makeLine(monthAttr, fillColor: .white, strokeColor: .white, strokeWidth: 26.0)
        let titleLineFill = makeLine(monthAttr, fillColor: .black, strokeColor: nil, strokeWidth: nil)

        let titleWidth = CTLineGetTypographicBounds(titleLineFill, nil, nil, nil)
        let textOriginX = (pageWidth - CGFloat(titleWidth)) / 2
        let baselineY = pageHeight - outerMargin - monthAscent
        let textOrigin = CGPoint(x: textOriginX, y: baselineY)

        context.textPosition = textOrigin
        CTLineDraw(titleLineHalo, context)
        context.textPosition = textOrigin
        CTLineDraw(titleLineFill, context)

        let weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let borderColor = UColor(white: 0.55, alpha: 0.85).cgColor
        let weekdayCellFill = UColor.white.cgColor
        let weekendCellFill = UColor.rgb255(252, 230, 230, 1.0).cgColor
        let weekdayHeaderFill = UColor.white.cgColor
        let weekendHeaderFill = UColor.rgb255(250, 217, 217, 1.0).cgColor
        let weekdayTextColor = UColor(white: 0.18, alpha: 1)
        let weekendTextColor = UColor.rgb255(184, 56, 56, 1.0)
        let weekdayDayNumberColor = UColor(white: 0.16, alpha: 0.85)
        let weekendDayNumberColor = UColor.rgb255(184, 56, 56, 0.92)

        func isWeekend(_ column: Int) -> Bool { column >= 5 }

        func rectFromTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
            CGRect(x: x, y: pageHeight - y - height, width: width, height: height)
        }

        for column in 0..<7 {
            let x = outerMargin + CGFloat(column) * cellWidth
            let headerRect = rectFromTop(x: x, y: gridTop, width: cellWidth, height: weekdayHeaderHeight)
            context.setFillColor(isWeekend(column) ? weekendHeaderFill : weekdayHeaderFill)
            context.fill(headerRect)
            context.setStrokeColor(borderColor)
            context.stroke(headerRect, width: 1)

            drawCenteredText(
                weekdayNames[column],
                in: headerRect.insetBy(dx: 6, dy: 6),
                font: UFont.boldSystemFont(ofSize: 13),
                color: isWeekend(column) ? weekendTextColor : weekdayTextColor,
                in: context
            )
        }

        for row in 0..<rows {
            for column in 0..<7 {
                let x = outerMargin + CGFloat(column) * cellWidth
                let y = gridTop + weekdayHeaderHeight + CGFloat(row) * cellHeight
                let cellRect = rectFromTop(x: x, y: y, width: cellWidth, height: cellHeight)

                context.setFillColor(isWeekend(column) ? weekendCellFill : weekdayCellFill)
                context.fill(cellRect)
                context.setStrokeColor(borderColor)
                context.stroke(cellRect, width: 1)

                let dayIndex = row * 7 + column - mondayBasedOffset + 1
                guard monthRange.contains(dayIndex) else { continue }

                let numberRect = cellRect.insetBy(dx: 8, dy: 8)
                drawLeftAlignedText(
                    "\(dayIndex)",
                    in: numberRect,
                    font: UFont.systemFont(ofSize: 15, weight: .regular),
                    color: isWeekend(column) ? weekendDayNumberColor : weekdayDayNumberColor,
                    in: context
                )
            }
        }
    }

    private static func drawCenteredText(_ text: String, in rect: CGRect, font: UFont, color: UColor, in ctx: CGContext) {
        let attr = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color
        ])
        let line = makeLine(attr, fillColor: color, strokeColor: nil, strokeWidth: nil)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        let originX = rect.midX - width / 2
        let originY = rect.midY - (ascent - descent) / 2
        ctx.textPosition = CGPoint(x: originX, y: originY)
        CTLineDraw(line, ctx)
    }

    private static func drawLeftAlignedText(_ text: String, in rect: CGRect, font: UFont, color: UColor, in ctx: CGContext) {
        let attr = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color
        ])
        let line = makeLine(attr, fillColor: color, strokeColor: nil, strokeWidth: nil)
        let originX = rect.minX
        let originY = rect.maxY - font.ascender
        ctx.textPosition = CGPoint(x: originX, y: originY)
        CTLineDraw(line, ctx)
    }

    /// Creates a CTLine with explicit foreground / stroke attributes applied to every run.
    /// CTLine respects the CTM exactly the same way on macOS and iOS, unlike
    /// `NSAttributedString.draw(at:)` which inherits UIKit's flipped y-axis on iOS
    /// and would render upside-down inside our bottom-up CG context.
    private static func makeLine(
        _ attr: NSAttributedString,
        fillColor: UColor,
        strokeColor: UColor?,
        strokeWidth: CGFloat?
    ) -> CTLine {
        let copy = NSMutableAttributedString(attributedString: attr)
        var added: [NSAttributedString.Key: Any] = [
            .foregroundColor: fillColor
        ]
        if let strokeColor, let strokeWidth {
            added[.strokeColor] = strokeColor
            added[.strokeWidth] = strokeWidth
        }
        copy.addAttributes(added, range: NSRange(location: 0, length: copy.length))
        return CTLineCreateWithAttributedString(copy as CFAttributedString)
    }
}
