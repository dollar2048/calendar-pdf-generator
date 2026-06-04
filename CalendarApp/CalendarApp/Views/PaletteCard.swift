import SwiftUI
#if os(iOS)
import PhotosUI
#else
import ImageIO
import UniformTypeIdentifiers
#endif

/// A single tappable preview tile rendering one calendar background.
struct PaletteCard: View {
    let spec: CalendarSpec
    let background: CalendarBackground

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
            .aspectRatio(841.89 / 595.28, contentMode: .fit)

            Text(background.displayName)
                .font(.headline)
                .padding(.leading, 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        )
        .task(id: renderKey) {
            await generateThumbnail()
        }
    }

    // Re-render whenever the palette/variation OR the chosen month/year changes.
    private var renderKey: String {
        "\(background.id)-\(spec.month)-\(spec.year)"
    }

    @MainActor
    private func generateThumbnail() async {
        let snapshotSpec = spec
        let snapshotBackground = background
        thumbnail = nil
        let image = await Task.detached(priority: .userInitiated) {
            CalendarPDFRenderer.renderPreviewImage(spec: snapshotSpec, background: snapshotBackground, scale: 0.9)
        }.value
        thumbnail = image
    }
}

/// A tile for an imported background image: tap to open, with a delete button.
struct CustomBackgroundCard: View {
    let spec: CalendarSpec
    let custom: CustomBackground
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
            PaletteCard(spec: spec, background: .custom(custom))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button(action: onDelete) {
                Label("Delete background", systemImage: "trash.circle.fill")
            }
            .labelStyle(.iconOnly)
            .font(.title2)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, .red)
            .buttonStyle(.plain)
            .padding(14)
        }
    }
}

/// The always-present "Add your own" picker tile. Imports an image and hands
/// back its CGImage; the gallery owns the list of imported backgrounds.
struct AddBackgroundCard: View {
    let onPicked: (CGImage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    picker
                }
            }
            .aspectRatio(841.89 / 595.28, contentMode: .fit)

            Text("Add your own")
                .font(.headline)
                .padding(.leading, 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        )
    }

    // MARK: - Platform pickers

    #if os(iOS)
    @State private var photoItem: PhotosPickerItem?

    @ViewBuilder
    private var picker: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            Label("Add your own", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .onChange(of: photoItem) { _, newValue in
            guard let newValue else { return }
            Task { await loadPhoto(newValue) }
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        defer { photoItem = nil }
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data),
            let cgImage = uiImage.cgImage
        else { return }
        onPicked(cgImage)
    }
    #else
    @State private var showImporter = false

    @ViewBuilder
    private var picker: some View {
        Button { showImporter = true } label: {
            Label("Add your own", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.image]) { result in
            guard case let .success(url) = result else { return }
            loadFile(url)
        }
    }

    private func loadFile(_ url: URL) {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return }
        onPicked(cgImage)
    }
    #endif
}
