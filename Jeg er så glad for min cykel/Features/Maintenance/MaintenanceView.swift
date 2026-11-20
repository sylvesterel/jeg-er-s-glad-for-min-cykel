import SwiftUI

/// Vedligeholdelse i to trin: vælg udstyr, og få en plan til netop din cykel.
struct MaintenanceView: View {
    @State private var model: MaintenanceViewModel
    @State private var showsPlan = false
    @Environment(\.dismiss) private var dismiss

    init(bike: Bike) {
        _model = State(initialValue: MaintenanceViewModel(bike: bike))
    }

    var body: some View {
        NavigationStack {
            EquipmentStep(model: model)
                .safeAreaInset(edge: .bottom) {
                    PrimaryButton(title: "Se din plan") { showsPlan = true }
                }
                .navigationDestination(isPresented: $showsPlan) { PlanStep(model: model) }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Trin 1: udstyr

private struct EquipmentStep: View {
    @Bindable var model: MaintenanceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trin 1 af 2").sectionLabel()
                    Text("Hvad har du derhjemme?")
                        .font(.largeTitle.bold())
                    Text("Vælg det, du har. Så laver vi en plan, der passer til dig og din cykel.")
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Equipment.allCases) { item in
                        EquipmentCard(item: item, isOn: model.owned.contains(item)) { model.toggle(item) }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Hvor ofte cykler du?").sectionLabel()
                    Card {
                        ForEach(RideFrequency.allCases) { frequency in
                            Button { model.frequency = frequency } label: {
                                HStack {
                                    Text(frequency.title)
                                    Spacer()
                                    if model.frequency == frequency {
                                        Image(systemName: "checkmark")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.tint)
                                    }
                                }
                                .padding(.vertical, 14)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(model.frequency == frequency ? .isSelected : [])
                            if frequency != RideFrequency.allCases.last { Divider() }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .sensoryFeedback(.selection, trigger: model.owned)
        .sensoryFeedback(.selection, trigger: model.frequency)
    }
}

private struct EquipmentCard: View {
    let item: Equipment
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Image(systemName: item.symbol)
                        .font(.title2)
                        .frame(height: 30)
                    Spacer()
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                        .contentTransition(.symbolEffect(.replace))
                }
                .padding(.bottom, 12)
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(item.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isOn ? Color.accentColor : .clear, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.2), value: isOn)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// MARK: - Trin 2: plan

private struct PlanStep: View {
    let model: MaintenanceViewModel
    @State private var guide: Repair?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trin 2 af 2").sectionLabel()
                    Text("Din plan")
                        .font(.largeTitle.bold())
                    Text("Til din \(model.bike.name) med \(model.bike.drivetrain.title.lowercased()) og \(model.bike.brakes.title.lowercased()).")
                        .foregroundStyle(.secondary)
                    if !model.guideTasks.isEmpty {
                        Text("Ugens og månedens \(model.guideTasks.count) opgaver tager ca. \(Text("\(model.guideMinutes) min").foregroundStyle(.tint).fontWeight(.semibold)).")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(model.groups, id: \.interval) { group in
                    section(group.interval.title) {
                        ForEach(group.tasks) { task in
                            TaskRow(task: task, missing: []).divided(unless: task.id == group.tasks.last?.id)
                        }
                    }
                }

                if !model.blocked.isEmpty {
                    section("Køb for at kunne") {
                        ForEach(model.blocked) { task in
                            TaskRow(task: task, missing: model.missing(for: task))
                                .divided(unless: task.id == model.blocked.last?.id)
                        }
                    }
                }

                section("Hos en cykelsmed") {
                    HStack(spacing: 14) {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundStyle(.secondary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Årligt eftersyn hos en cykelsmed")
                                .font(.body.weight(.medium))
                            Text("Bremser, gear og hjul justeres")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text("ca. \(Text(MaintenanceCatalog.servicePrice, format: .dkk))")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .padding(.vertical, 14)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Start vedligeholdelse") { guide = model.guideRepair }
                .disabled(model.guideRepair == nil)
        }
        .fullScreenCover(item: $guide) { GuideView(repair: $0, bike: model.bike) }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).sectionLabel()
            Card(content: content)
        }
    }
}

private struct TaskRow: View {
    let task: MaintenanceTask
    /// Tom = man har alt.
    let missing: [Equipment]

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: task.part.symbol)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.body.weight(.medium))
                Text("\(task.minutes) min · \(task.part.title)")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                if missing.isEmpty {
                    Label {
                        Text("Du har alt").foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "checkmark").foregroundStyle(.green)
                    }
                    .font(.footnote.weight(.medium))
                    .padding(.top, 2)
                } else {
                    Text("Mangler: \(missing.map { $0.title.lowercased() }.joined(separator: ", "))")
                        .font(.footnote.weight(.medium))
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .opacity(missing.isEmpty ? 1 : 0.5)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Fælles

private struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

private struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .font(.headline)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

private extension View {
    @ViewBuilder
    func divided(unless isLast: Bool) -> some View {
        if isLast { self } else { VStack(spacing: 0) { self; Divider() } }
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

#Preview {
    MaintenanceView(bike: Catalog.bikes[0])
}
