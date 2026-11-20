import Charts
import SwiftUI

/// Fanen "Profil": hvad du har sparet, dine cykler og din historik.
struct ProfileView: View {
    private let profile = Profile.mock

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ProfileHeader(profile: profile)
                    SavingsCard(profile: profile)
                    StatsGrid(profile: profile)
                    BikesSection()
                    HistorySection(history: Array(profile.history.prefix(5)), count: profile.history.count)
                    MilestonesSection(milestones: profile.milestones)
                    SettingsSection()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Delte stilarter

private let danish = Locale(identifier: "da_DK")

private struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}

private extension View {
    func card(padding: CGFloat = 24, radius: CGFloat = 28) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: radius))
    }
}

// MARK: - Header

private struct ProfileHeader: View {
    let profile: Profile

    var body: some View {
        HStack(spacing: 16) {
            Text(profile.initials)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .frame(width: 68, height: 68)
                .background(Color.accentColor.opacity(0.14), in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.title2.bold())
                Text("Pendler · \(profile.city)\nMedlem siden \(String(profile.memberSince))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Sparet i alt

private struct SavingsCard: View {
    let profile: Profile
    @State private var shown = 0

    var body: some View {
        let points = profile.savingsThisYear
        let thisYear = points.last?.total ?? 0

        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "Sparet i alt")
            Text(shown, format: .dkk)
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(shown)))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(thisYear.formatted(.dkk)) i \(String(profile.year)) · i forhold til at betale en cykelsmed")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(points, id: \.date) { point in
                    AreaMark(x: .value("Dato", point.date), y: .value("Sparet", point.total))
                        .interpolationMethod(.stepEnd)
                        .foregroundStyle(Color.accentColor.opacity(0.12))
                    LineMark(x: .value("Dato", point.date), y: .value("Sparet", point.total))
                        .interpolationMethod(.stepEnd)
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
                if let last = points.last {
                    PointMark(x: .value("Dato", last.date), y: .value("Sparet", last.total))
                        .foregroundStyle(Color.accentColor)
                        .symbolSize(40)
                }
            }
            .chartXScale(domain: yearDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
                }
            }
            .chartYAxis(.hidden)
            .environment(\.locale, danish)
            .frame(height: 120)
            .padding(.top, 20)
            .accessibilityLabel("Besparelse i \(String(profile.year)): \(thisYear.formatted(.dkk))")
        }
        .card()
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.smooth(duration: 1.2)) { shown = profile.totalSaved }
        }
    }

    private var yearDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: profile.year, month: 1, day: 1))!
        return start...calendar.date(byAdding: .year, value: 1, to: start)!
    }
}

// MARK: - Nøgletal

private struct StatsGrid: View {
    let profile: Profile

    var body: some View {
        let hours = profile.hoursWrenched.formatted(.number.precision(.fractionLength(0...1)).locale(danish))
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                StatTile(value: "\(profile.history.count)", unit: nil, label: "Reparationer")
                StatTile(value: hours, unit: "t", label: "Skruet selv")
            }
            GridRow {
                StatTile(value: profile.kmThisYear.formatted(.number.locale(danish)), unit: "km", label: "Pendlet i år")
                StatTile(value: "\(profile.co2SavedKg)", unit: "kg", label: "CO₂ sparet")
            }
        }
    }
}

private struct StatTile: View {
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: label)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                if let unit {
                    Text(unit)
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .card(padding: 20, radius: 24)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Mine cykler

private struct BikesSection: View {
    @Environment(Garage.self) private var garage
    @State private var isAddingBike = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Mine cykler")
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(garage.bikes) { bike in
                        Button {
                            withAnimation(.snappy) { garage.bike = bike }
                        } label: {
                            BikeCard(bike: bike, isActive: bike == garage.bike)
                        }
                        .buttonStyle(.plain)
                    }
                    Button { isAddingBike = true } label: { AddBikeCard() }
                        .buttonStyle(.plain)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
        .sensoryFeedback(.selection, trigger: garage.bike)
        .sheet(isPresented: $isAddingBike) { AddBikeView() }
    }
}

private struct BikeCard: View {
    let bike: Bike
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if isActive {
                    // Kun én 3D-visning på siden; tryk går til kortet, ikke til modellen.
                    Bike3DView(bike: bike).allowsHitTesting(false)
                } else {
                    Image(systemName: "bicycle")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)

            Spacer(minLength: 12)

            Text(bike.name)
                .font(.headline)
                .lineLimit(1)
            HStack {
                Text("\(bike.type.title) · \(String(bike.year))")
                    .foregroundStyle(.secondary)
                Spacer()
                if isActive {
                    Text("Aktiv")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .font(.footnote)
            .padding(.top, 2)
        }
        .padding(18)
        .frame(width: 232, height: 220)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.accentColor, lineWidth: isActive ? 1.5 : 0)
        }
        .contentShape(.rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

private struct AddBikeCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.title2.weight(.medium))
            Text("Tilføj cykel")
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(.secondary)
        .frame(width: 140, height: 220)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
        }
        .contentShape(.rect(cornerRadius: 24))
    }
}

// MARK: - Historik

private struct HistorySection: View {
    let history: [Profile.Entry]
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Seneste reparationer")
            VStack(spacing: 0) {
                ForEach(Array(history.enumerated()), id: \.element.id) { index, entry in
                    HistoryRow(entry: entry, isFirst: index == 0, isLast: index == history.count - 1)
                }
            }
            .card(padding: 20)
        }
    }
}

private struct HistoryRow: View {
    let entry: Profile.Entry
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Tidslinje: prik og forbindende streg.
            VStack(spacing: 0) {
                Circle()
                    .fill(isFirst ? Color.accentColor : Color(.tertiaryLabel))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1)
                    .opacity(isLast ? 0 : 1)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.repair.title)
                    .font(.subheadline.weight(.medium))
                Text(entry.date.formatted(dateStyle))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 20)

            Spacer(minLength: 8)

            Text("+\(entry.repair.savings.formatted(.dkk))")
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var dateStyle: Date.FormatStyle {
        let sameYear = Calendar.current.isDate(entry.date, equalTo: .now, toGranularity: .year)
        let style = Date.FormatStyle(locale: danish).day().month(.wide)
        return sameYear ? style : style.year()
    }
}

// MARK: - Milepæle

private struct MilestonesSection: View {
    let milestones: [Profile.Milestone]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Milepæle")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: 3), spacing: 20) {
                ForEach(milestones) { milestone in
                    VStack(spacing: 10) {
                        Image(systemName: milestone.symbol)
                            .font(.system(size: 20, weight: .regular))
                            .frame(width: 56, height: 56)
                            .overlay {
                                Circle().strokeBorder(
                                    milestone.isUnlocked ? AnyShapeStyle(.primary.opacity(0.8)) : AnyShapeStyle(.quaternary),
                                    style: StrokeStyle(lineWidth: 1.2, dash: milestone.isUnlocked ? [] : [3, 4])
                                )
                            }
                        Text(milestone.title)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(milestone.isUnlocked ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(milestone.isUnlocked ? "Opnået" : "Ikke opnået")
                }
            }
            .card(padding: 20)
        }
    }
}

// MARK: - Indstillinger

private struct SettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Indstillinger")
            VStack(spacing: 0) {
                AppearanceRow()
                Divider().padding(.leading, 52)
                SettingsRow(title: "Notifikationer", symbol: "bell")
                Divider().padding(.leading, 52)
                SettingsRow(title: "Enheder", symbol: "ruler", value: "Kilometer")
                Divider().padding(.leading, 52)
                SettingsRow(title: "Privatliv", symbol: "hand.raised")
                Divider().padding(.leading, 52)
                SettingsRow(title: "Om appen", symbol: "info.circle")
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))

            Button("Log ud", role: .destructive) {}
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
                .padding(.top, 12)
        }
    }
}

private struct AppearanceRow: View {
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                Text("Tema")
            }
            Picker("Tema", selection: $appearance) {
                Text("Automatisk").tag("system")
                Text("Lys").tag("light")
                Text("Mørk").tag("dark")
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .sensoryFeedback(.selection, trigger: appearance)
    }
}

private struct SettingsRow: View {
    let title: String
    let symbol: String
    var value: String? = nil

    var body: some View {
        NavigationLink {
            // ponytail: indstillinger er ikke bygget endnu.
            ContentUnavailableView(title, systemImage: symbol, description: Text("Kommer snart."))
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                Text(title)
                Spacer()
                if let value {
                    Text(value).foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let garage = Garage()
    for id in ["specialized-allez", "bullitt-classic", "avenue-broadway"] {
        garage.bike = Catalog.bikes.first { $0.id == id }
    }
    return ProfileView().environment(garage)
}
