import SwiftUI

struct RepairDetailView: View {
    let repair: Repair
    let bike: Bike
    @State private var showGuide = false
    @State private var showMechanics = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Bike3DView(bike: bike, highlight: repair.part, focusesHighlight: true)
                    .containerRelativeFrame(.vertical) { height, _ in height * 0.45 }

                VStack(alignment: .leading, spacing: 32) {
                    header
                    PriceSection(repair: repair)
                    if !repair.tools.isEmpty { tools }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(.background)
        .safeAreaInset(edge: .bottom) { actions }
        .navigationTitle(repair.part.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showGuide) { GuideView(repair: repair, bike: bike) }
        .sheet(isPresented: $showMechanics) { MechanicMapView() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(repair.title)
                .font(.title.bold())
            Text(repair.summary)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                DifficultyBadge(difficulty: repair.difficulty)
                Text("·")
                Text("ca. \(repair.minutes) min")
                if repair.difficulty.isDIY {
                    Text("·")
                    Text("\(repair.steps.count) trin")
                }
            }
            .font(.subheadline.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Det skal du bruge").sectionLabel()
            VStack(alignment: .leading, spacing: 0) {
                ForEach(repair.tools, id: \.self) { tool in
                    Text(tool)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                    if tool != repair.tools.last { Divider() }
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 4) {
            if repair.difficulty.isDIY {
                Label("Hvert trin vises som 3D-animation", systemImage: "play.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                Button { showGuide = true } label: {
                    Text("Start guiden").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                if repair.difficulty == .hard {
                    Button("Vil du hellere have en cykelsmed til det?") { showMechanics = true }
                        .font(.subheadline)
                        .padding(.top, 8)
                }
            } else {
                Button { showMechanics = true } label: {
                    Text("Find en cykelsmed").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
        }
        .controlSize(.large)
        .font(.headline)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

/// Prisgennemsigtighed: hvad koster det hos mekanikeren, og hvad sparer du?
private struct PriceSection: View {
    let repair: Repair

    private var isDIY: Bool { repair.difficulty.isDIY }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isDIY ? "Du sparer" : "Det koster cirka").sectionLabel()
                Text(isDIY ? repair.savings : repair.mechanicPrice, format: .dkk)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isDIY ? Color.accentColor : .primary)
            }

            if isDIY {
                bar
                HStack(alignment: .top) {
                    figure("Hos en cykelsmed", repair.mechanicPrice)
                    figure("Gør det selv", repair.partsCost)
                }
            } else {
                HStack(alignment: .top) {
                    figure("Nye dele", repair.partsCost)
                    figure("Betaling for arbejdet", repair.savings)
                }
            }

            Text(isDIY
                 ? "Det koster det typisk hos en dansk cykelsmed, inkl. nye dele."
                 : "Det koster det typisk hos en dansk cykelsmed, inkl. nye dele. Er prisen meget højere, så spørg hvorfor.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }

    /// Hele baren er mekanikerprisen: det mørke stykke betaler du selv, det orange sparer du.
    private var bar: some View {
        let share = Double(repair.partsCost) / Double(max(repair.mechanicPrice, 1))
        return GeometryReader { proxy in
            HStack(spacing: 2) {
                Capsule().fill(.primary).frame(width: max(proxy.size.width * share, 3))
                Capsule().fill(Color.accentColor)
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }

    private func figure(_ label: String, _ amount: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(amount, format: .dkk)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private extension Text {
    func sectionLabel() -> some View {
        font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}

#Preview("Gør det selv") {
    NavigationStack { RepairDetailView(repair: Catalog.repairs[0], bike: Catalog.bikes[0]) }
}

#Preview("Mekaniker") {
    NavigationStack {
        RepairDetailView(repair: Catalog.repairs.first { $0.difficulty == .mechanic }!, bike: Catalog.bikes[0])
    }
}
