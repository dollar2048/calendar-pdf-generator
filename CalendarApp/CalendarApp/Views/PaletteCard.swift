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
        .task(id: background.id) {
            await generateThumbnail()
        }
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

/// Gallery tile for importing a user image. Empty state shows an "Add your own"
/// affordance; once an image is chosen it renders that page and tapping opens it.
struct AddBackgroundCard: View {
    let spec: CalendarSpec
    let custom: CustomBackground?
    let onPicked: (CGImage) -> Void
    let onOpen: () -> Void
    let onRemove: () -> Void

    var body: some View {
        if let custom {
            chosenCard(custom)
        } else {
            emptyCard
        }
    }

    @ViewBuilder
    private func chosenCard(_ custom: CustomBackground) -> some View {
        VStack(spacing: 0) {
            Button(action: onOpen) {
                PaletteCard(spec: spec, background: .custom(custom))
            }
            .buttonStyle(.plain)

            picker(label: "Replace image", systemImage: "photo.on.rectangle")
                .padding(.top, 4)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onRemove) {
                Label("Remove", systemImage: "xmark.circle.fill")
            }
            .labelStyle(.iconOnly)
            .font(.title3)
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
            .padding(14)
        }
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    picker(label: "Add your own", systemImage: "plus")
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
    private func picker(label: String, systemImage: String) -> some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            Label(label, systemImage: systemImage)
        }
        .buttonStyle(.bordered)
        .onChange(of: photoItem) { _, newValue in
            guard let newValue else { return }
            Task { await loadPhoto(newValue) }
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data),
            let cgImage = uiImage.cgImage
        else { return }
        onPicked(cgImage)
        photoItem = nil
    }
    #else
    @State private var showImporter = false

    @ViewBuilder
    private func picker(label: String, systemImage: String) -> some View {
        Button { showImporter = true } label: {
            Label(label, systemImage: systemImage)
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
