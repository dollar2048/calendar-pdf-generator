import SwiftUI
import UniformTypeIdentifiers

struct DetailView: View {
    let spec: CalendarSpec
    let background: CalendarBackground

    @Environment(\.dismiss) private var dismiss
    @State private var pdfData: Data?
    @State private var showShare = false
    @State private var showSaveSuccess = false

    private var fileBaseName: String {
        "\(spec.monthName)-\(spec.year)-calendar-\(background.fileStem)"
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
        "\(background.id)-\(spec.month)-\(spec.year)"
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(spec.monthName) \(spec.year)")
                    .font(.headline)
                Text(background.displayName)
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

            // Close on the trailing edge per Apple HIG.
            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark.circle.fill")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
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
        let snapshotBackground = background
        pdfData = nil
        let data = await Task.detached(priority: .userInitiated) {
            CalendarPDFRenderer.renderPDFData(spec: snapshotSpec, background: snapshotBackground)
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
