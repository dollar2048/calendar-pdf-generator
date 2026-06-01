import SwiftUI
import UniformTypeIdentifiers

struct DetailView: View {
    let spec: CalendarSpec
    let palette: Palette

    @Environment(\.dismiss) private var dismiss
    @State private var pdfData: Data?
    @State private var showShare = false
    @State private var showSaveSuccess = false

    private var fileBaseName: String {
        "\(spec.monthName)-\(spec.year)-calendar-\(palette.id)"
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 540)
        #endif
        .task(id: paletteKey) {
            await regenerate()
        }
    }

    private var paletteKey: String {
        "\(palette.id)-\(spec.month)-\(spec.year)"
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark.circle.fill")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(spec.monthName) \(spec.year)")
                    .font(.headline)
                Text(palette.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            #if os(macOS)
            Button {
                savePDFViaPanel()
            } label: {
                Label("Save PDF…", systemImage: "square.and.arrow.down")
            }
            .disabled(pdfData == nil)
            #else
            Button {
                showShare = true
            } label: {
                Label("Share PDF", systemImage: "square.and.arrow.up")
            }
            .disabled(pdfData == nil)
            #endif
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        #if os(iOS)
        .sheet(isPresented: $showShare) {
            if let url = writeToTempFile() {
                ShareSheet(items: [url])
            }
        }
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if let pdfData {
            PDFKitView(data: pdfData)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @MainActor
    private func regenerate() async {
        let snapshotSpec = spec
        let snapshotPalette = palette
        pdfData = nil
        let data = await Task.detached(priority: .userInitiated) {
            CalendarPDFRenderer.renderPDFData(spec: snapshotSpec, palette: snapshotPalette)
        }.value
        pdfData = data
    }

    private func writeToTempFile() -> URL? {
        guard let pdfData else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileBaseName).pdf")
        do {
            try pdfData.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    #if os(macOS)
    private func savePDFViaPanel() {
        guard let pdfData else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(fileBaseName).pdf"
        if panel.runModal() == .OK, let url = panel.url {
            try? pdfData.write(to: url, options: .atomic)
        }
    }
    #endif
}
