import SwiftUI

struct GalleryView: View {
    @State private var spec = CalendarSpec.current
    @State private var variation = 0
    @State private var customBackgrounds: [CustomBackground] = []
    @State private var selection: CalendarBackground?
    @State private var showDatePopover = false

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 18)
    ]

    private var paletteBackgrounds: [CalendarBackground] {
        Palettes.all.map { .palette($0, variation: variation) }
    }

    var body: some View {
        #if os(macOS)
        macContent
        #else
        NavigationStack {
            grid
                .navigationTitle("\(spec.monthName) \(String(spec.year))")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        shuffleButton
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        dateButton
                    }
                }
        }
        #endif
    }

    @ViewBuilder
    private var macContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Text("Calendar Generator")
                    .font(.title2.weight(.semibold))
                Spacer()
                shuffleButton
                monthPicker
                yearStepper
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.thinMaterial)

            grid
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(paletteBackgrounds) { background in
                    Button {
                        selection = background
                    } label: {
                        PaletteCard(spec: spec, background: background)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(customBackgrounds) { custom in
                    CustomBackgroundCard(
                        spec: spec,
                        custom: custom,
                        onOpen: { selection = .custom(custom) },
                        onDelete: { customBackgrounds.removeAll { $0.id == custom.id } }
                    )
                }

                AddBackgroundCard { cgImage in
                    let new = CustomBackground(image: cgImage)
                    customBackgrounds.append(new)
                    selection = .custom(new)
                }
            }
            .padding(20)
        }
        .sheet(item: $selection) { background in
            DetailView(spec: spec, background: background)
        }
    }

    // MARK: - Controls

    private var shuffleButton: some View {
        Button {
            variation += 1
        } label: {
            Label("Shuffle backgrounds", systemImage: "shuffle")
        }
        .labelStyle(.iconOnly)
    }

    #if os(iOS)
    private var dateButton: some View {
        Button {
            showDatePopover = true
        } label: {
            Label("Month and Year", systemImage: "calendar")
        }
        .popover(isPresented: $showDatePopover) {
            datePopover
                .presentationCompactAdaptation(.popover)
        }
    }

    private var datePopover: some View {
        VStack(alignment: .leading, spacing: 18) {
            LabeledContent("Month") {
                Picker("Month", selection: $spec.month) {
                    ForEach(1...12, id: \.self) { m in
                        Text(monthName(m)).tag(m)
                    }
                }
                .labelsHidden()
            }

            Stepper(value: $spec.year, in: 1900...2999) {
                LabeledContent("Year", value: String(spec.year))
            }
        }
        .padding(20)
        .frame(minWidth: 260)
    }
    #endif

    private var monthPicker: some View {
        Picker("Month", selection: $spec.month) {
            ForEach(1...12, id: \.self) { m in
                Text(monthName(m)).tag(m)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .fixedSize()
    }

    private var yearStepper: some View {
        HStack(spacing: 4) {
            Stepper(value: $spec.year, in: 1900...2999) {
                Text(verbatim: String(spec.year))
                    .monospacedDigit()
                    .font(.body.weight(.medium))
                    .frame(minWidth: 56)
            }
            .labelsHidden()
            Text(verbatim: String(spec.year))
                .monospacedDigit()
                .font(.body.weight(.medium))
                .frame(minWidth: 56, alignment: .leading)
        }
        .fixedSize()
    }

    private func monthName(_ m: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "LLLL"
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2000, month: m, day: 1))!
        return f.string(from: date)
    }
}

#Preview {
    GalleryView()
}
