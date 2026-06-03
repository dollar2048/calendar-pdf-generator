import Foundation
import CoreGraphics

struct Palette: Identifiable, Hashable {
    let id: String
    let displayName: String
    let leafColors: [UColor]
    let flowerColors: [UColor]
    let berryColors: [UColor]
    let accentColors: [UColor]

    static func == (lhs: Palette, rhs: Palette) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum Palettes {
    static let all: [Palette] = [
        Palette(
            id: "vibrant",
            displayName: "Vibrant",
            leafColors: [.rgb255(120, 190, 60), .rgb255(70, 160, 60), .rgb255(170, 215, 70), .rgb255(40, 120, 50), .rgb255(95, 175, 70)],
            flowerColors: [.rgb255(255, 200, 50), .rgb255(240, 100, 130), .rgb255(255, 170, 40), .rgb255(140, 110, 200)],
            berryColors: [.rgb255(230, 40, 50), .rgb255(200, 30, 60), .rgb255(245, 80, 60)],
            accentColors: [.rgb255(110, 80, 180), .rgb255(70, 130, 220), .rgb255(255, 120, 60)]
        ),
        Palette(
            id: "summer",
            displayName: "Summer",
            leafColors: [.rgb255(110, 200, 90), .rgb255(70, 175, 80), .rgb255(160, 220, 100), .rgb255(50, 145, 75), .rgb255(200, 230, 110)],
            flowerColors: [.rgb255(255, 220, 60), .rgb255(255, 110, 130), .rgb255(255, 165, 70), .rgb255(255, 90, 110)],
            berryColors: [.rgb255(255, 80, 90), .rgb255(220, 50, 70), .rgb255(255, 150, 60)],
            accentColors: [.rgb255(70, 180, 230), .rgb255(255, 200, 80), .rgb255(255, 130, 90)]
        ),
        Palette(
            id: "sea",
            displayName: "Sea",
            leafColors: [.rgb255(60, 165, 165), .rgb255(40, 130, 150), .rgb255(110, 200, 195), .rgb255(20, 100, 130), .rgb255(150, 215, 200)],
            flowerColors: [.rgb255(255, 195, 150), .rgb255(255, 230, 200), .rgb255(180, 220, 240), .rgb255(255, 150, 130)],
            berryColors: [.rgb255(255, 110, 90), .rgb255(220, 80, 100), .rgb255(70, 160, 200)],
            accentColors: [.rgb255(230, 200, 150), .rgb255(50, 110, 170), .rgb255(255, 180, 140)]
        ),
        Palette(
            id: "playgrounds",
            displayName: "Playgrounds",
            leafColors: [.rgb255(80, 200, 90), .rgb255(40, 160, 60), .rgb255(150, 220, 70), .rgb255(20, 130, 50)],
            flowerColors: [.rgb255(255, 215, 0), .rgb255(230, 50, 80), .rgb255(60, 140, 240), .rgb255(255, 130, 40)],
            berryColors: [.rgb255(230, 30, 50), .rgb255(255, 180, 0), .rgb255(60, 150, 230)],
            accentColors: [.rgb255(180, 80, 200), .rgb255(255, 110, 60), .rgb255(50, 180, 220)]
        ),
        Palette(
            id: "spring",
            displayName: "Spring",
            leafColors: [.rgb255(140, 200, 70), .rgb255(95, 175, 65), .rgb255(180, 220, 90), .rgb255(60, 130, 55), .rgb255(110, 185, 80)],
            flowerColors: [.rgb255(255, 205, 70), .rgb255(245, 130, 160), .rgb255(170, 130, 230), .rgb255(255, 165, 90)],
            berryColors: [.rgb255(225, 50, 60), .rgb255(200, 35, 55)],
            accentColors: [.rgb255(140, 90, 200), .rgb255(90, 140, 220), .rgb255(255, 145, 60)]
        ),
        Palette(
            id: "autumn",
            displayName: "Autumn",
            leafColors: [.rgb255(220, 130, 50), .rgb255(170, 90, 40), .rgb255(240, 180, 60), .rgb255(120, 70, 30), .rgb255(190, 110, 50)],
            flowerColors: [.rgb255(255, 110, 50), .rgb255(255, 200, 60), .rgb255(220, 70, 80), .rgb255(255, 160, 80)],
            berryColors: [.rgb255(200, 40, 40), .rgb255(160, 60, 30), .rgb255(230, 80, 50)],
            accentColors: [.rgb255(160, 80, 30), .rgb255(200, 130, 50), .rgb255(140, 50, 80)]
        ),
        Palette(
            id: "pastel",
            displayName: "Pastel",
            leafColors: [.rgb255(170, 220, 170), .rgb255(130, 200, 160), .rgb255(210, 230, 180), .rgb255(100, 180, 140)],
            flowerColors: [.rgb255(255, 195, 210), .rgb255(225, 195, 240), .rgb255(255, 230, 170), .rgb255(255, 215, 180)],
            berryColors: [.rgb255(235, 130, 150), .rgb255(200, 150, 220), .rgb255(255, 160, 140)],
            accentColors: [.rgb255(180, 200, 230), .rgb255(230, 215, 170), .rgb255(220, 180, 230)]
        ),
        Palette(
            id: "tropical",
            displayName: "Tropical",
            leafColors: [.rgb255(50, 140, 90), .rgb255(80, 175, 105), .rgb255(20, 95, 65), .rgb255(120, 200, 95), .rgb255(60, 160, 110)],
            flowerColors: [.rgb255(255, 80, 140), .rgb255(255, 200, 50), .rgb255(80, 200, 220), .rgb255(255, 130, 60)],
            berryColors: [.rgb255(220, 50, 60), .rgb255(255, 130, 40), .rgb255(200, 30, 80)],
            accentColors: [.rgb255(170, 60, 160), .rgb255(50, 170, 200), .rgb255(255, 110, 60)]
        ),
        Palette(
            id: "monochrome-green",
            displayName: "Monochrome Green",
            leafColors: [.rgb255(95, 155, 80), .rgb255(60, 120, 60), .rgb255(140, 195, 100), .rgb255(35, 95, 50), .rgb255(180, 215, 120)],
            flowerColors: [.rgb255(200, 220, 140), .rgb255(230, 240, 180), .rgb255(170, 200, 100)],
            berryColors: [.rgb255(70, 110, 55), .rgb255(130, 165, 70)],
            accentColors: [.rgb255(110, 145, 70), .rgb255(160, 185, 90)]
        ),
        Palette(
            id: "winter",
            displayName: "Winter",
            leafColors: [.rgb255(55, 105, 90), .rgb255(35, 80, 70), .rgb255(110, 150, 140), .rgb255(150, 185, 180), .rgb255(80, 130, 120)],
            flowerColors: [.rgb255(240, 248, 252), .rgb255(205, 226, 240), .rgb255(255, 255, 255), .rgb255(186, 210, 230)],
            berryColors: [.rgb255(198, 40, 50), .rgb255(168, 28, 44), .rgb255(224, 72, 70)],
            accentColors: [.rgb255(118, 158, 198), .rgb255(180, 202, 222), .rgb255(86, 126, 168)]
        )
    ]
}

/// A chosen background for a calendar page: either one of the built-in
/// procedural palettes (with a re-rollable variation seed) or a user-supplied image.
enum CalendarBackground: Identifiable, Hashable {
    case palette(Palette, variation: Int)
    case custom(CustomBackground)

    var id: String {
        switch self {
        case let .palette(palette, variation): "\(palette.id)#\(variation)"
        case let .custom(custom): "custom-\(custom.id.uuidString)"
        }
    }

    var displayName: String {
        switch self {
        case let .palette(palette, _): palette.displayName
        case .custom: "My Background"
        }
    }

    /// Filename-safe stem used when exporting the PDF.
    var fileStem: String {
        switch self {
        case let .palette(palette, _): palette.id
        case .custom: "custom"
        }
    }
}

/// A user-imported background image. Identity is the UUID so the enum stays
/// Hashable without hashing pixel data; the CGImage rides along for rendering.
struct CustomBackground: Identifiable, Hashable {
    let id: UUID
    let image: CGImage

    init(id: UUID = UUID(), image: CGImage) {
        self.id = id
        self.image = image
    }

    static func == (lhs: CustomBackground, rhs: CustomBackground) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
