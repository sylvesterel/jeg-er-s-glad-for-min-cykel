import SwiftUI

/// Hjemmeskærmen "Værksted": 3D-cyklen er selve grænsefladen. Tryk på en del for at se reparationerne.
struct GarageView: View {
    @Environment(Garage.self) private var garage

    var body: some View {
        NavigationStack {
            if let bike = garage.bike {
                GarageHome(model: GarageViewModel(bike: bike))
                    .id(bike.id)
            }
        }
    }
}

private struct GarageHome: View {
    @Environment(Garage.self) private var garage
    @State var model: GarageViewModel
    @State private var isAddingBike = false
    @State private var isMaintaining = false
    /// Valgt i arket; skubbes først når arket er gledet ned.
    @State private var pendingRepair: Repair?
    @State private var openRepair: Repair?
    @State private var bottomInset: CGFloat = 0

    private static let peekHeight: CGFloat = 220

    var body: some View {
        // 3D-cyklen fylder hele skærmen; header og delvælger svæver ovenpå.
        Bike3DView(
            bike: model.bike,
            highlight: model.selectedPart,
            focusesHighlight: model.selectedPart != nil,
            hotspots: Set(model.parts),
            onTapPart: { part in model.selectedPart = part }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
                // Blød overgang, så teksten kan læses når kameraet zoomer ind under den.
                .background {
                    LinearGradient(
                        stops: [.init(color: Color(.systemGroupedBackground), location: 0.6), .init(color: .clear, location: 1)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
        }
        .overlay(alignment: .bottom) { footer }
        .background(Color(.systemGroupedBackground))
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { bottomInset = $0 }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.spring(duration: 0.4), value: model.selectedPart)
        .sensoryFeedback(.selection, trigger: model.selectedPart)
        .sheet(isPresented: showsPartSheet, onDismiss: pushPendingRepair) {
            if let part = model.selectedPart {
                PartSheet(part: part, repairs: model.repairs(for: part)) { pendingRepair = $0 }
                    .presentationDetents([.height(Self.peekHeight), .medium, .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
        }
        .sheet(isPresented: $isAddingBike) { AddBikeView() }
        .sheet(isPresented: $isMaintaining) { MaintenanceView(bike: model.bike) }
        .navigationDestination(item: $openRepair) { repair in
            RepairDetailView(repair: repair, bike: model.bike)
        }
    }

    /// Arket vises mens en del er valgt, men skjules mens en reparation er åben,
    /// så det kommer igen når man går tilbage. Lukker brugeren det, fravælges delen.
    private var showsPartSheet: Binding<Bool> {
        Binding {
            model.selectedPart != nil && pendingRepair == nil && openRepair == nil
        } set: { isPresented in
            if !isPresented, pendingRepair == nil, openRepair == nil { model.selectedPart = nil }
        }
    }

    private func pushPendingRepair() {
        openRepair = pendingRepair
        pendingRepair = nil
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Min cykel")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(.secondary)

            bikeTitle

            if model.potentialSavings > 0 {
                Text("Spar op til \(Text(model.potentialSavings, format: .dkk).foregroundStyle(.tint).fontWeight(.semibold)) ved at gøre det selv")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Button("Vedligehold cyklen", systemImage: "wrench.and.screwdriver") { isMaintaining = true }
                .font(.subheadline.weight(.medium))
                .buttonStyle(.glass)
                .tint(.primary)
                .padding(.top, 8)
                // Et ark kan ikke vises oven på delens ark.
                .allowsHitTesting(model.selectedPart == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var bikeTitle: some View {
        let title = Text(model.bike.name)
            .font(.title.weight(.semibold))
            .foregroundStyle(.primary)

        if garage.bikes.count > 1 {
            Menu {
                Picker("Cykel", selection: Binding { garage.bike } set: { garage.bike = $0 }) {
                    ForEach(garage.bikes) { bike in
                        Text(bike.name).tag(Optional(bike))
                    }
                }
                Divider()
                Button("Tilføj cykel", systemImage: "plus") { isAddingBike = true }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    title
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.primary)
            .accessibilityHint("Skift cykel")
            // Et ark kan ikke vises oven på delens ark, så skift cykel når ingen del er valgt.
            .allowsHitTesting(model.selectedPart == nil)
        } else {
            title
        }
    }

    // MARK: - Bund

    @ViewBuilder
    private var footer: some View {
        if model.parts.isEmpty {
            Text("Guides til din cykel er på vej")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        } else {
            VStack(spacing: 16) {
                if model.selectedPart == nil {
                    Text("Tryk på en del af cyklen")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
                PartSelector(parts: model.parts, selection: model.selectedPart) { model.toggle($0) }
            }
            .padding(.bottom, 16)
            // Løft vælgeren over arket, når det står i sin laveste højde.
            .padding(.bottom, model.selectedPart == nil ? 0 : max(Self.peekHeight + 32 - bottomInset, 0))
        }
    }
}

/// Vandret række af glas-kapsler; et tilgængeligt alternativ til at trykke på 3D-modellen.
private struct PartSelector: View {
    let parts: [BikePart]
    let selection: BikePart?
    let onSelect: (BikePart) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(parts) { part in
                            chip(part)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .onChange(of: selection) {
                guard let selection else { return }
                withAnimation { proxy.scrollTo(selection, anchor: .center) }
            }
        }
    }

    private func chip(_ part: BikePart) -> some View {
        let isSelected = part == selection
        return Button { onSelect(part) } label: {
            Label(part.title, systemImage: part.symbol)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .glassEffect(isSelected ? .regular.tint(.accentColor).interactive() : .regular.interactive(), in: .capsule)
        .id(part)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Arket med reparationerne for den valgte del.
private struct PartSheet: View {
    let part: BikePart
    let repairs: [Repair]
    let onOpen: (Repair) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(repairs.count == 1 ? "1 reparation" : "\(repairs.count) reparationer")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                Text(part.title)
                    .font(.title2.weight(.semibold))
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)

            List(repairs) { repair in
                Button { onOpen(repair) } label: { RepairRow(repair: repair) }
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .animation(.default, value: part)
    }
}

private struct RepairRow: View {
    let repair: Repair

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(repair.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(repair.difficulty.isDIY ? "\(repair.difficulty.title) · \(repair.minutes) min" : "\(repair.minutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Group {
                if repair.difficulty.isDIY {
                    Text("Spar \(Text(repair.savings, format: .dkk))")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                } else {
                    Text("Hos en cykelsmed")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .monospacedDigit()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
    }
}

#Preview {
    GarageView()
        .environment({
            let garage = Garage()
            garage.bike = Catalog.bikes[0]
            return garage
        }())
}
