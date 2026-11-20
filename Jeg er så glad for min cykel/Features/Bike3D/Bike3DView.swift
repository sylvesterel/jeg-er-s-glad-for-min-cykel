import RealityKit
import SwiftUI

/// Procedural 3D-cykel. Træk vandret for at dreje; drejer langsomt af sig selv.
/// `highlight` farver én del i accentfarven (pulserende) og gør resten grå.
struct Bike3DView: View {
    let bike: Bike
    var highlight: BikePart? = nil
    /// Zoom kameraet ind på `highlight`.
    var focusesHighlight: Bool = false
    /// Dele der vises som trykbare hotspots på modellen.
    var hotspots: Set<BikePart> = []
    /// Kaldes når brugeren trykker på en del af cyklen. nil = ingen tryk.
    var onTapPart: ((BikePart) -> Void)? = nil
    /// Afspil en guide-animation i loop (nil = ingen). Kameraet rammer selv handlingen ind.
    var animation: StepAnimation? = nil
    /// Pause/afspil for `animation`; afspilning fortsætter fra samme billede.
    var isPlaying: Bool = true
    /// Skift værdien for at starte `animation` forfra ("Se igen").
    var replayToken: Int = 0

    var body: some View {
        // Ny cykel = ny scene; alt andet ændrer kun materialer, kamera, led og overlays.
        Bike3DCanvas(bike: bike, highlight: highlight, focuses: focusesHighlight, hotspots: hotspots, onTapPart: onTapPart, scan: nil,
                     animation: animation, isPlaying: isPlaying, replayToken: replayToken)
            .id(bike.id)
    }
}

/// Falsk 3D-scanning til "Scan din cykel": en vandret scanningsring løfter sig over cyklen.
/// Over ringen ses cyklen som en svag trådmodel, i ringens kølvand i accentfarven, og under den i fuldt materiale.
/// Ved `progress` 1 ser den ud som `Bike3DView`.
struct BikeScanView: View {
    let bike: Bike
    let progress: Double

    var body: some View {
        Bike3DCanvas(bike: bike, highlight: nil, focuses: false, hotspots: [], onTapPart: nil, scan: Float(min(max(progress, 0), 1)),
                     animation: nil, isPlaying: false, replayToken: 0)
            .id(bike.id)
    }
}

private struct Bike3DCanvas: View {
    let bike: Bike
    let highlight: BikePart?
    let focuses: Bool
    let hotspots: Set<BikePart>
    let onTapPart: ((BikePart) -> Void)?
    let scan: Float?
    let animation: StepAnimation?
    let isPlaying: Bool
    let replayToken: Int
    @State private var scene = Bike3DScene()
    @State private var taps = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        realityView
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
            guard size.width > 0, size.height > 0 else { return }
            scene.size = size
        }
        .onChange(of: highlight) { scene.highlight = highlight }
        .onChange(of: focuses) { scene.focuses = focuses }
        .onChange(of: hotspots) { scene.hotspots = hotspots }
        .onChange(of: colorScheme) { scene.isDark = colorScheme == .dark }
        .onChange(of: scan) { scene.scan = scan }
        .onChange(of: animation) { scene.animation = animation }
        .onChange(of: isPlaying) { scene.isPlaying = isPlaying }
        .onChange(of: replayToken) { scene.restartAnimation() }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if let part = Bike3DScene.part(of: value.entity) { tap(part) }
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { scene.drag(by: $0.translation.width) }
                .onEnded { _ in scene.endDrag() }
        )
        .overlay {
            HotspotLayer(scene: scene, selected: highlight, isTappable: onTapPart != nil, onTap: tap)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
    }

    private var realityView: some View {
        RealityView { content in
            scene.highlight = highlight
            scene.focuses = focuses
            scene.hotspots = hotspots
            scene.isDark = colorScheme == .dark
            scene.scan = scan
            scene.animation = animation
            scene.isPlaying = isPlaying
            scene.setUp(&content, bike: bike)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("3D-model af \(bike.name)"))
        .accessibilityHint(Text("Træk vandret for at dreje cyklen"))
    }

    private func tap(_ part: BikePart) {
        guard let onTapPart else { return }
        taps += 1
        onTapPart(part)
    }
}

/// Hotspots tegnet i SwiftUI oven på 3D-scenen: skarpe i alle zoomniveauer og trykbare med VoiceOver.
private struct HotspotLayer: View {
    let scene: Bike3DScene
    let selected: BikePart?
    let isTappable: Bool
    let onTap: (BikePart) -> Void

    var body: some View {
        ZStack {
            ForEach(scene.markers) { marker in
                Button { onTap(marker.part) } label: {
                    HotspotMarker(isSelected: marker.part == selected)
                        .opacity(marker.front || marker.part == selected ? 1 : 0.45)
                        // Kun valget fjedrer; positionen må aldrig animere.
                        .animation(.spring(duration: 0.35), value: marker.part == selected)
                        .frame(width: 44, height: 44)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(isTappable)
                .accessibilityLabel(marker.part.title)
                .accessibilityAddTraits(marker.part == selected ? .isSelected : [])
                .position(marker.point)
                .transaction { $0.animation = nil }
            }
        }
    }
}

private struct HotspotMarker: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            if !isSelected {
                // ponytail: statisk ring i stedet for pulserende phaseAnimator. En animation her
                // kombineres med markørens position hvert billede og kostede ~60 % CPU.
                Circle()
                    .stroke(Color("AccentColor").opacity(0.45), lineWidth: 1.5)
                    .frame(width: 26, height: 26)
            }
            Circle()
                .fill(Color("AccentColor"))
                .stroke(Color(.systemBackground), lineWidth: isSelected ? 3 : 2)
                .frame(width: isSelected ? 22 : 14, height: isSelected ? 22 : 14)
            if isSelected {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 7, height: 7)
                    .transition(.scale)
            }
        }
    }
}

// MARK: - Previews

#Preview("Typer") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(BikeType.allCases) { type in
                let bike = Catalog.bikes.first { $0.type == type }!
                Bike3DView(bike: bike, highlight: type == .road ? .chain : nil)
                    .frame(height: 280)
                    .background(.background.secondary, in: .rect(cornerRadius: 24))
            }
        }
        .padding()
    }
}

#Preview("Tryk, hotspots og fokus") {
    @Previewable @State var selected: BikePart?
    @Previewable @State var focus = true
    VStack {
        Bike3DView(
            bike: Catalog.bikes[0],
            highlight: selected,
            focusesHighlight: focus,
            hotspots: Set(BikePart.allCases),
            onTapPart: { selected = selected == $0 ? nil : $0 }
        )
        Toggle("Fokus", isOn: $focus).padding()
        Text(selected?.title ?? "Tryk på en del af cyklen").font(.headline)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Fokus: bremser") {
    Bike3DView(bike: Catalog.bikes[0], highlight: .brakes, focusesHighlight: true, hotspots: [.brakes, .tire, .chain])
        .background(Color(.systemGroupedBackground))
}

#Preview("Scanning") {
    VStack(spacing: 12) {
        ForEach([0.0, 0.35, 0.7, 1.0], id: \.self) { p in
            BikeScanView(bike: Catalog.bikes[0], progress: p)
                .frame(height: 170)
                .overlay(alignment: .topLeading) { Text(p, format: .percent).font(.caption).padding(8) }
        }
    }
    .padding()
}

#Preview("Scanning, animeret") {
    @Previewable @State var progress = 0.0
    BikeScanView(bike: Catalog.bikes[0], progress: progress)
        .task {
            while progress < 1 {
                try? await Task.sleep(for: .milliseconds(120))
                progress = min(progress + 0.02, 1)
            }
        }
}

#Preview("Guide-animationer") {
    @Previewable @State var animation: StepAnimation = .flipBike
    @Previewable @State var isPlaying = true
    @Previewable @State var replay = 0
    @Previewable @State var bikeIndex = 1
    let bike = Catalog.bikes[bikeIndex]
    let part: BikePart = switch animation {
    case .flipBike, .inspect, .tightenBolt, .loosenBolt: .saddle
    case .removeFrontWheel, .removeRearWheel, .spinWheel, .deflateTire, .pumpTire, .leverTire: .tire
    case .turnPedals, .oilChain, .wipeChain, .removeChain: .chain
    case .squeezeBrake, .replaceBrakePads, .adjustCable: .brakes
    case .shiftGears: .gears
    case .moveSaddle: .saddle
    case .alignHandlebar: .handlebar
    case .switchLight: .lights
    case .unscrewPedal: .pedals
    }
    VStack(spacing: 16) {
        Bike3DView(bike: bike, highlight: part, focusesHighlight: true, animation: animation, isPlaying: isPlaying, replayToken: replay)
            .frame(height: 420)
        Picker("Animation", selection: $animation) {
            ForEach(StepAnimation.allCases, id: \.self) { Text($0.rawValue) }
        }
        Picker("Cykel", selection: $bikeIndex) {
            ForEach(Catalog.bikes.indices, id: \.self) { Text(Catalog.bikes[$0].name) }
        }
        HStack {
            Button(isPlaying ? "Pause" : "Afspil") { isPlaying.toggle() }
            Button("Se igen") { replay += 1 }
            Button("Næste") {
                let all = StepAnimation.allCases
                animation = all[(all.firstIndex(of: animation)! + 1) % all.count]
            }
        }
        .buttonStyle(.bordered)
    }
    .padding(.vertical)
}
