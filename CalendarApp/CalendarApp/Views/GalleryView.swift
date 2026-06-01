import SwiftUI

struct GalleryView: View {
    @State private var spec = CalendarSpec.current
    @State private var selectedPalette: Palette? = nil

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 18)
    ]

    var body: some View {
        #if os(macOS)
        macContent
        #else
        NavigationStack {
            iosContent
                .navigationTitle("\(spec.monthName) \(String(spec.year))")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        monthYearMenu
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

    @ViewBuilder
    private var iosContent: some View {
        grid
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(Palettes.all) { palette in
                    PaletteCard(spec: spec, palette: palette)
                        .onTapGesture { selectedPalette = palette }
                }
            }
            .padding(20)
        }
        .sheet(item: $selectedPalette) { palette in
            DetailView(spec: spec, palette: palette)
        }
    }

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

    private var monthYearMenu: some View {
        Menu {
            Picker("Month", selection: $spec.month) {
                ForEach(1...12, id: \.self) { m in
                    Text(monthName(m)).tag(m)
                }
            }
            Picker("Year", selection: $spec.year) {
                ForEach(yearRange, id: \.self) { y in
                    Text(verbatim: String(y)).tag(y)
                }
            }
        } label: {
            Label("Month and Year", systemImage: "calendar")
        }
    }

    private var yearRange: [Int] {
        let center = spec.year
        return Array((center - 5)...(center + 10))
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
