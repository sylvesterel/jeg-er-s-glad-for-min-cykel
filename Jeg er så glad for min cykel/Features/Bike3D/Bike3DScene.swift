import RealityKit
import SwiftUI

/// Et hotspot projiceret til skærmen.
struct Bike3DMarker: Identifiable, Equatable {
    let part: BikePart
    var point: CGPoint
    /// false = delen sidder på cyklens bagside lige nu.
    var front: Bool
    var id: BikePart { part }
}

/// Holder 3D-scenen: drejning (træk + langsom drejeskive), fremhævning, fokus, hotspots, scanning og kameraets indramning.
/// Geometrien bygges én gang i `setUp`; alt andet ændrer kun materialer, kamera og overlays.
@Observable
final class Bike3DScene {
    /// Hotspots i skærmkoordinater; det eneste SwiftUI observerer.
    private(set) var markers: [Bike3DMarker] = []

    @ObservationIgnored private let pivot = Entity()
    @ObservationIgnored private let model = Entity()
    @ObservationIgnored private let camera = PerspectiveCamera()
    @ObservationIgnored private let scanRing = Entity()
    @ObservationIgnored private var pieces: [Bike3DPiece] = []
    @ObservationIgnored private var pieceY: [(min: Float, max: Float)] = []
    @ObservationIgnored private var pieceState: [Int] = []
    @ObservationIgnored private var spots: [BikePart: PartSpot] = [:]
    @ObservationIgnored private var radius: Float = 1      // cyklens radius i xz-planet (det den fejer ved drejning)
    @ObservationIgnored private var halfHeight: Float = 0.5
    @ObservationIgnored private var minY: Float = -0.5
    @ObservationIgnored private var time: Float = 0
    @ObservationIgnored private var yaw: Float = -0.5
    @ObservationIgnored private var dragStartYaw: Float?
    @ObservationIgnored private var seeksFocus = false
    @ObservationIgnored private var eye: SIMD3<Float> = [0, 0, 5]
    @ObservationIgnored private var target: SIMD3<Float> = .zero
    @ObservationIgnored private var scanShown: Float = 0
    @ObservationIgnored private var subscription: EventSubscription?
    @ObservationIgnored private var animator: BikeAnimator?
    /// Bygger animatoren første gang en animation starter (30–40 ms + værktøj, som de fleste skærme aldrig bruger).
    @ObservationIgnored private var makeAnimator: (() -> BikeAnimator)?
    @ObservationIgnored private var framing: BikeFraming?
    @ObservationIgnored private var rootOffset: SIMD3<Float> = .zero
    @ObservationIgnored private var animationTime: Float = 0

    @ObservationIgnored var size = CGSize(width: 390, height: 300) {
        didSet {
            aspect = Float(size.width / size.height)
            snapCamera()
        }
    }
    @ObservationIgnored private var aspect: Float = 1.3
    @ObservationIgnored var highlight: BikePart? {
        didSet { if highlight != oldValue { seeksFocus = true; updateFraming(); applyMaterials() } }
    }
    @ObservationIgnored var focuses = false {
        didSet { if focuses != oldValue { seeksFocus = true } }
    }
    @ObservationIgnored var hotspots: Set<BikePart> = [] {
        didSet { hotspotOrder = BikePart.allCases.filter(hotspots.contains) }
    }
    @ObservationIgnored private var hotspotOrder: [BikePart] = []
    @ObservationIgnored private var markerBuffer: [Bike3DMarker] = []
    /// Guide-animation i loop; nil = normal visning.
    @ObservationIgnored var animation: StepAnimation? {
        didSet { if animation != oldValue { ensureAnimator(); restartAnimation(); applyMaterials() } }
    }
    @ObservationIgnored var isPlaying = true
    @ObservationIgnored var isDark = false {
        didSet {
            accent = Self.accent(dark: isDark)
            pulse = Self.pulseMaterials(accent)
            scanMaterials = Self.scanMaterials(accent, dark: isDark)
            applyMaterials()
            animator?.setColors(accent: accent, dark: isDark)
        }
    }
    /// Accentfarven for det aktuelle tema. Caches, så den ikke slås op hvert billede.
    @ObservationIgnored private var accent = Bike3DScene.accent(dark: false)
    /// Forudberegnede pulstrin for den fremhævede del; skiftes kun når trinnet ændrer sig.
    @ObservationIgnored private var pulse = Bike3DScene.pulseMaterials(Bike3DScene.accent(dark: false))
    @ObservationIgnored private var pulseLevel = -1
    /// Trådmodel over og i scanningsringen; bygges kun ved temaskift.
    @ObservationIgnored private var scanMaterials = Bike3DScene.scanMaterials(Bike3DScene.accent(dark: false), dark: false)
    @ObservationIgnored private var scanOpacity: Float = -1
    /// nil = normal visning; 0...1 = scanning i gang.
    @ObservationIgnored var scan: Float? { didSet { if oldValue == nil { applyMaterials() } } }

    private var isFocused: Bool { focuses && highlight != nil && scan == nil }

    func setUp(_ content: inout RealityViewCameraContent, bike: Bike) {
        let builder = BikeBuilder(bike: bike)
        let root = builder.build()
        pieces = builder.pieces
        spots = builder.spots

        // Centrér cyklen om drejeaksen og mål den til kameraet.
        let bounds = root.visualBounds(relativeTo: nil)
        root.position = -bounds.center
        rootOffset = root.position
        radius = simd_length(SIMD2(bounds.extents.x, bounds.extents.z)) / 2
        halfHeight = bounds.extents.y / 2
        minY = -halfHeight
        model.addChild(root)
        pivot.addChild(model)
        for key in spots.keys {
            spots[key]!.marker -= bounds.center
            spots[key]!.center -= bounds.center
        }
        pieceY = pieces.map {
            let b = $0.entity.visualBounds(relativeTo: pivot)
            return (b.min.y, b.max.y)
        }
        pieceState = Array(repeating: -1, count: pieces.count)
        let whole = BikeFraming(center: bounds.center, radius: radius, facing: [0, 0, 1], elevation: 0.14)
        makeAnimator = { [rig = builder.rig, model, spots = builder.spots] in
            BikeAnimator(rig: rig, root: root, model: model, whole: whole, spots: spots)
        }
        ensureAnimator()
        updateFraming()

        let key = DirectionalLight()
        key.light.intensity = 2500
        key.look(at: .zero, from: [1.5, 3, 2.5], relativeTo: nil)
        let rim = DirectionalLight()
        rim.light.intensity = 1200
        rim.look(at: .zero, from: [-2, 1.5, -2], relativeTo: nil)

        camera.camera.fieldOfViewInDegrees = 28
        if let scan { scanShown = scan; buildScanRing() }

        content.camera = .virtual
        content.add(pivot)
        content.add(key)
        content.add(rim)
        content.add(camera)
        content.add(scanRing)
        tick(0)
        snapCamera()
        applyMaterials()

        subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.tick(Float(event.deltaTime))
        }
    }

    func drag(by dx: CGFloat) {
        if dragStartYaw == nil { dragStartYaw = yaw }
        seeksFocus = false
        yaw = (dragStartYaw ?? yaw) + Float(dx) * 0.012
    }

    func endDrag() { dragStartYaw = nil }

    /// Start animationen forfra (bløder over fra den aktuelle stilling).
    func restartAnimation() {
        animationTime = 0
        seeksFocus = true
        animator?.beginTransition()
        updateFraming()
    }

    private func ensureAnimator() {
        guard animator == nil, animation != nil, let makeAnimator else { return }
        let animator = makeAnimator()
        animator.setColors(accent: accent, dark: isDark)
        self.animator = animator
        self.makeAnimator = nil
    }

    private func updateFraming() {
        framing = animation.flatMap { animator?.framing($0, highlight: highlight) }
    }

    /// Delen et ramt entity hører til (gå op til delens gruppe).
    static func part(of entity: Entity) -> BikePart? {
        var current: Entity? = entity
        while let e = current {
            if let part = BikePart(rawValue: e.name) { return part }
            current = e.parent
        }
        return nil
    }

    // MARK: - Pr. billede

    private func tick(_ dt: Float) {
        time += dt
        let ease = 1 - exp(-dt * 5)   // billedfrekvens-uafhængig udglatning

        if animation != nil, isPlaying { animationTime += dt }
        if dragStartYaw == nil {
            if framing != nil, animation == .inspect {
                if isPlaying { yaw += dt * 0.25 }
            } else if let framing {
                if seeksFocus {
                    let goal = atan2(-framing.facing.x, framing.facing.z)
                    yaw += remainder(goal - yaw, 2 * .pi) * ease
                }
            } else if isFocused, seeksFocus, let spot = highlight.flatMap({ spots[$0] }) {
                let goal = atan2(-spot.facing.x, spot.facing.z)
                yaw += remainder(goal - yaw, 2 * .pi) * ease
            } else if !isFocused {
                // Langsommere med hotspots: de følger med uden at SwiftUI skal lægge dem ud hvert billede.
                yaw += dt * (hotspots.isEmpty ? 0.3 : 0.08)
            }
        }
        pivot.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])

        let goal = cameraGoal()
        eye += (goal.eye - eye) * ease
        target += (goal.target - target) * ease
        camera.look(at: target, from: eye, relativeTo: nil)

        if let highlight, scan == nil {
            let glow = 0.5 + 0.5 * sin(time * 2 * .pi / 1.6)
            let level = min(Int(glow * Float(pulse.count)), pulse.count - 1)
            if level != pulseLevel {
                pulseLevel = level
                for piece in pieces where piece.part == highlight {
                    piece.entity.model?.materials = [pulse[level]]
                }
            }
        }
        if let animator, animation != nil || !animator.isSettled {
            let t = animation.map { animationTime.truncatingRemainder(dividingBy: animator.duration($0)) } ?? 0
            animator.apply(animation, t: t, dt: dt, highlight: highlight)
        }
        if let scan { updateScan(scan, ease: 1 - exp(-dt * 3)) }
        updateMarkers()
    }

    // MARK: - Kamera

    private var vfov: Float { camera.camera.fieldOfViewInDegrees * .pi / 180 }

    private func cameraGoal() -> (eye: SIMD3<Float>, target: SIMD3<Float>) {
        let hfov = 2 * atan(tan(vfov / 2) * aspect)
        if let framing, scan == nil {
            let center = pivot.orientation.act(framing.center + rootOffset)
            let distance = framing.radius / sin(min(vfov, hfov) / 2)
            let e = framing.elevation
            return (center + SIMD3(0, sin(e), cos(e)) * distance, center)
        }
        if isFocused, let spot = highlight.flatMap({ spots[$0] }) {
            // Delen (mindst 30 cm, så der er kontekst) udfylder ca. halvdelen af den smalleste akse.
            let center = pivot.orientation.act(spot.center)
            let r = max(spot.radius, 0.3)
            let distance = r / tan(min(vfov, hfov) / 2) / 0.5 + r
            let elevation: Float = 0.22
            return (center + SIMD3(0, sin(elevation), cos(elevation)) * distance, center)
        }
        let distance = max(radius / sin(hfov / 2), halfHeight / tan(vfov / 2) + radius) * 1.04
        let elevation: Float = 0.14
        return ([0, distance * sin(elevation), distance * cos(elevation)], .zero)
    }

    /// Ny rammestørrelse: spring direkte til målet i stedet for at animere.
    private func snapCamera() {
        (eye, target) = cameraGoal()
        camera.look(at: target, from: eye, relativeTo: nil)
    }

    // MARK: - Materialer

    private static func accent(dark: Bool) -> UIColor {
        (UIColor(named: "AccentColor") ?? .tintColor).resolvedColor(with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light))
    }

    private static func scanMaterials(_ accent: UIColor, dark: Bool) -> (ghost: UnlitMaterial, wire: UnlitMaterial) {
        (BikeBuilder.wire(dark ? .white : .black, opacity: dark ? 0.14 : 0.10), BikeBuilder.wire(accent, opacity: 0.85))
    }

    private static func pulseMaterials(_ color: UIColor) -> [PhysicallyBasedMaterial] {
        (0..<8).map { BikeBuilder.highlight(color, glow: (Float($0) + 0.5) / 8) }
    }

    private func applyMaterials() {
        pulseLevel = -1
        guard scan == nil else { return pieceState = pieceState.map { _ in -1 } }
        let active = BikeBuilder.highlight(accent, glow: 0.5)
        let faded = BikeBuilder.faded(dark: isDark)
        for piece in pieces {
            let material: any RealityKit.Material = switch highlight {
            case nil: piece.material
            case piece.part: active
            default: faded
            }
            piece.entity.model?.materials = [material]
        }
    }

    // MARK: - Hotspots

    private func updateMarkers() {
        guard !hotspots.isEmpty, size.width > 0 else {
            if !markers.isEmpty { markers = [] }
            return
        }
        let view = camera.transformMatrix(relativeTo: nil).inverse
        let centerDepth = (view * SIMD4<Float>(0, 0, 0, 1)).z
        let t = tan(vfov / 2)
        markerBuffer.removeAll(keepingCapacity: true)
        for part in hotspotOrder {
            guard let spot = spots[part] else { continue }
            let p = view * SIMD4(pivot.orientation.act(spot.marker), 1)
            guard p.z < -0.01 else { continue }
            let x = CGFloat(p.x / -p.z / (t * aspect) + 1) / 2 * size.width
            let y = CGFloat(1 - p.y / -p.z / t) / 2 * size.height
            guard (-20...size.width + 20).contains(x), (-20...size.height + 20).contains(y) else { continue }
            markerBuffer.append(Bike3DMarker(part: part, point: CGPoint(x: x.rounded(), y: y.rounded()), front: p.z > centerDepth - 0.04))
        }
        // Udgiv kun ved mindst 1 pt bevægelse eller skift for/bag; ellers lægger SwiftUI laget ud hvert billede.
        let old = markers
        let changed = markerBuffer.count != old.count || zip(markerBuffer, old).contains { new, old in
            new.part != old.part || new.front != old.front
                || abs(new.point.x - old.point.x) >= 1 || abs(new.point.y - old.point.y) >= 1
        }
        if changed { markers = markerBuffer }
    }

    // MARK: - Scanning

    private func buildScanRing() {
        let r = radius * 1.02
        var line = UnlitMaterial(color: accent)
        line.blending = .transparent(opacity: .init(floatLiteral: 0.9))
        var fill = UnlitMaterial(color: accent)
        fill.blending = .transparent(opacity: .init(floatLiteral: 0.03))
        let flat = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        let edge = ModelEntity(mesh: BikeBuilder.ring(outer: r, inner: r - 0.006, depth: 0.001, chamfer: 0), materials: [line])
        let disc = ModelEntity(mesh: .generateCylinder(height: 0.0005, radius: r - 0.006), materials: [fill])
        edge.orientation = flat
        scanRing.addChild(edge)
        scanRing.addChild(disc)
    }

    private func updateScan(_ goal: Float, ease: Float) {
        scanShown += (goal - scanShown) * ease
        if abs(goal - scanShown) < 0.001 { scanShown = goal }
        let s = scanShown
        let band = halfHeight * 0.6
        let line = minY + (2 * halfHeight + band) * s
        scanRing.position.y = min(line, minY + 2 * halfHeight + 0.02)
        scanRing.isEnabled = s > 0.001 && s < 0.999
        let opacity = min(1, s * 25, (1 - s) * 10)
        if opacity != scanOpacity {
            scanOpacity = opacity
            scanRing.components.set(OpacityComponent(opacity: opacity))
        }

        let (ghost, wire) = scanMaterials
        for (i, piece) in pieces.enumerated() {
            let reveal = (line - pieceY[i].min) / band
            let state = reveal < 0 ? 0 : reveal < 1 ? 1 : 2
            guard state != pieceState[i] else { continue }
            pieceState[i] = state
            piece.entity.model?.materials = [state == 0 ? ghost : state == 1 ? wire : piece.material]
        }
    }
}
