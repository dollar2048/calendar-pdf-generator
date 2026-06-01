import SwiftUI

struct PaletteCard: View {
    let spec: CalendarSpec
    let palette: Palette

    @State private var thumbnail: CGImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                if let thumbnail {
                    Image(decorative: thumbnail, scale: 1, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 12))
                } else {
                    ProgressView()
                }
            }
            .aspectRatio(841.89/595.28, contentMode: .fit)

            Text(palette.displayName)
                .font(.headline)
                .padding(.leading, 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        )
        .task(id: thumbnailKey) {
            await generateThumbnail()
        }
    }

    private var thumbnailKey: String {
        "\(palette.id)-\(spec.month)-\(spec.year)"
    }

    @MainActor
    private func generateThumbnail() async {
        let snapshotSpec = spec
        let snapshotPalette = palette
        thumbnail = nil
        let image = await Task.detached(priority: .userInitiated) {
            CalendarPDFRenderer.renderPreviewImage(spec: snapshotSpec, palette: snapshotPalette, scale: 0.9)
        }.value
        thumbnail = image
    }
}
