import SwiftUI

/// Tilføj en cykel: 3D-scanning, stelnummer eller liste.
/// Vises som onboarding (ingen cykel) eller i et `.sheet` (så med lukkeknap).
struct AddBikeView: View {
    enum Route: Hashable { case scan, frameNumber, list }

    @Environment(Garage.self) private var garage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var model = AddBikeViewModel()
    @Namespace private var zoom

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Så viser vi de reparationer, der passer præcis til din cykel – og hvad du sparer ved selv at lave dem.")
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        NavigationLink(value: Route.scan) { scanCard }
                            .matchedTransitionSource(id: Route.scan, in: zoom)
                        NavigationLink(value: Route.frameNumber) { frameNumberCard }
                    }
                    .buttonStyle(.plain)

                    NavigationLink("Vælg fra listen i stedet", value: Route.list)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tilføj din cykel")
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) { dismiss() }
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .scan:
                    AddBikeScanView(model: model, add: add)
                        .navigationTransition(.zoom(sourceID: Route.scan, in: zoom))
                case .frameNumber:
                    FrameNumberView(model: model, add: add)
                case .list:
                    BikePickerView(onSelect: add)
                }
            }
        }
    }

    private func add(_ bike: Bike) {
        garage.bike = bike
        if isPresented { dismiss() }
    }

    private var scanCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            ZStack {
                ViewfinderCorners(length: 22)
                    .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                Image(systemName: "bicycle")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(height: 140)

            optionLabel(caption: "3D-scanning", title: "Scan din cykel", subtitle: "Peg kameraet mod cyklen")
        }
        .padding(24)
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [Color(white: 0.2), Color(white: 0.07)], startPoint: .top, endPoint: .bottom),
            in: .rect(cornerRadius: 28)
        )
        .environment(\.colorScheme, .dark)
    }

    private var frameNumberCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(AddBikeViewModel.example)
                .font(.system(size: 30, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
            optionLabel(caption: "Stelnummer", title: "Indtast stelnummer", subtitle: "Et nummer slået ind i stellet – typisk under pedalerne")
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 28))
    }

    private func optionLabel(caption: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)
                Text(title).font(.title3.weight(.semibold))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.tint, in: .circle)
        }
        .contentShape(.rect)
    }
}

/// Fire hjørnebeslag som i en kamerasøger.
struct ViewfinderCorners: Shape {
    var length: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let corners: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: rect.minX, y: rect.minY), 1, 1),
            (CGPoint(x: rect.maxX, y: rect.minY), -1, 1),
            (CGPoint(x: rect.minX, y: rect.maxY), 1, -1),
            (CGPoint(x: rect.maxX, y: rect.maxY), -1, -1),
        ]
        for (point, dx, dy) in corners {
            path.move(to: CGPoint(x: point.x, y: point.y + dy * length))
            path.addLine(to: point)
            path.addLine(to: CGPoint(x: point.x + dx * length, y: point.y))
        }
        return path
    }
}

/// Resultatkort for både scanning og stelnummer.
struct BikeResultCard<Secondary: View>: View {
    let bike: Bike
    /// Fx "97 % match".
    let badge: String
    let add: () -> Void
    @ViewBuilder let secondary: Secondary

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Vi fandt din cykel")
                }
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(.secondary)
                Spacer()
                Text(badge)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(bike.brand)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(bike.model)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
                GridRow {
                    spec("Årgang", String(bike.year))
                    spec("Type", bike.type.title)
                }
                GridRow {
                    spec("Gear", bike.gears == 1 ? "Ingen gear" : "\(bike.gears) \(bike.drivetrain.title.lowercased())")
                    spec("Bremser", bike.brakes.title)
                }
            }

            VStack(spacing: 12) {
                Button(action: add) {
                    Text("Tilføj cykel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)

                secondary
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 32))
    }

    private func spec(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Text(value).font(.body.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Onboarding") {
    AddBikeView()
        .environment(Garage())
}

#Preview("Som sheet") {
    Color.clear.sheet(isPresented: .constant(true)) {
        AddBikeView()
    }
    .environment(Garage())
}

#Preview("Resultatkort") {
    BikeResultCard(bike: Catalog.bikes[0], badge: "97 % match", add: {}) {
        Button("Ikke den rigtige? Scan igen") {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
