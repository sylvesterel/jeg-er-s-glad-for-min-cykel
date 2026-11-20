import RealityKit
import UIKit

private typealias P = SIMD3<Float>

/// Kameraets indramning, i cyklens koordinater: området omkring `center` med `radius` fylder billedet,
/// `facing` vender mod kameraet, og `elevation` er vinklen ovenfra (radianer).
struct BikeFraming {
    var center: SIMD3<Float>
    var radius: Float
    var facing: SIMD3<Float>
    var elevation: Float
}

/// Guide-animationerne: én tidslinje pr. `StepAnimation`, der sætter cyklens led og værktøjerne ud fra loop-tiden `t`.
/// Hvert billede lægger animationens stilling oven på hvilestillingen i `target`; kun det animationen rører (nu eller
/// i forrige billede) skrives til entities, og kun når værdien ændrer sig. Ved skift blødes over fra den forrige stilling.
final class BikeAnimator {
    private let rig: BikeRig
    private let model: Entity
    private let whole: BikeFraming
    private let spots: [BikePart: PartSpot]

    // Alt der kan bevæge sig, med hvilestilling og synlighed.
    private var animated: [Entity] = []
    private var index: [ObjectIdentifier: Int] = [:]
    private var rest: [Transform] = []
    private var restAlpha: [Float] = []
    /// Stillingen `pose` bygger; lig `rest`/`restAlpha` for alt uden for `touched`.
    private var target: [Transform] = []
    private var targetAlpha: [Float] = []
    /// Indeks som `pose` har skrevet til i dette billede.
    private var touched = Set<Int>()
    /// Sidst skrevne transform og (blødt overgået) opacitet pr. entity.
    private var written: [Transform] = []
    private var alpha: [Float] = []
    /// Sidst skrevne opacitet pr. entity; komponenter skrives kun når værdien ændrer sig.
    private var appliedAlpha: [Float] = []
    private var snapshot: [(Transform, Float)] = []
    private var blend: Float = 1

    // Værktøj og pile, bygget langs lokal y (værktøjets akse), spidsen i origo.
    private let hexKey = Entity(), wrench = Entity(), screwdriver = Entity(), tireLever = Entity()
    private let pump = Entity(), pumpHandle = Entity(), bottle = Entity(), bottleBody = Entity(), drop = Entity(), cloth = Entity()
    private let beam = Entity(), turnArrow = Entity(), moveArrow = Entity()
    private let puffs = [Entity(), Entity(), Entity(), Entity()]
    private var toolParts: [ModelEntity] = []
    private var arrowParts: [ModelEntity] = []
    private var puffParts: [ModelEntity] = []
    private var hose: [P] = []

    /// Kædens forskydning pr. kranke-radian, afrundet så én omgang flytter et helt antal ledpar (sømløst loop).
    private let chainPerRadian: Float
    private let wornPad = pbr(UIColor(white: 0.32, alpha: 1), roughness: 0.9)
    private let lampOff = pbr(UIColor(white: 0.35, alpha: 1), roughness: 0.3)
    private var newPad = BikeBuilder.highlight(.orange, glow: 0.6)
    /// Lygtens lysstyrke i 8 trin (forlygte, baglygte), så tændingen ikke laver materialer pr. billede.
    private static let frontLit = (0..<8).map { emissive(UIColor(red: 1, green: 0.96, blue: 0.85, alpha: 1), intensity: 0.2 + 3 * (Float($0) + 0.5) / 8) }
    private static let rearLit = (0..<8).map { emissive(.systemRed, intensity: 0.2 + 2 * (Float($0) + 0.5) / 8) }

    var isSettled: Bool { blend >= 1 }

    init(rig: BikeRig, root: Entity, model: Entity, whole: BikeFraming, spots: [BikePart: PartSpot]) {
        self.rig = rig
        self.model = model
        self.whole = whole
        self.spots = spots
        let pitch = rig.chain.length / Float(rig.links.count)
        let perTurn = 2 * Float.pi * rig.chain.ringR
        chainPerRadian = ((perTurn / (2 * pitch)).rounded() * 2 * pitch) / (2 * .pi)

        buildTools()
        let tools = [hexKey, wrench, screwdriver, tireLever, pump, bottle, drop, cloth, beam, turnArrow, moveArrow] + puffs
        for tool in tools { root.addChild(tool) }

        var parts: [Entity] = [model, rig.frontWheel, rig.rearWheel, rig.cassette, rig.crank, rig.saddle, rig.handlebar]
        parts += rig.pedals + rig.levers.map(\.entity) + rig.pads.map(\.entity) + rig.links
        parts += [rig.shifter?.entity, rig.derailleur, rig.barrel?.entity, rig.frontTire].compactMap { $0 }
        for e in parts + [pumpHandle, bottleBody] { track(e, alpha: 1) }
        for e in tools { track(e, alpha: 0) }
    }

    private func track(_ e: Entity, alpha a: Float) {
        guard index[ObjectIdentifier(e)] == nil else { return }
        index[ObjectIdentifier(e)] = animated.count
        animated.append(e)
        rest.append(e.transform)
        target.append(e.transform)
        written.append(e.transform)
        restAlpha.append(a)
        targetAlpha.append(a)
        alpha.append(a)
        appliedAlpha.append(a)
        if a == 0 { e.isEnabled = false }
    }

    // MARK: - Tidslinjer

    /// Loop-længde i sekunder, inkl. pausen til sidst.
    func duration(_ animation: StepAnimation) -> Float {
        switch animation {
        case .flipBike: 4.4
        case .removeFrontWheel, .removeRearWheel: 4.2
        case .unscrewPedal, .oilChain, .pumpTire, .removeChain: 3.9
        case .tightenBolt, .loosenBolt: 3.3
        case .squeezeBrake: 3.2
        default: 3.6
        }
    }

    func framing(_ animation: StepAnimation, highlight: BikePart?) -> BikeFraming {
        let side: Float = rig.brakeOnLeft ? -1 : 1
        switch animation {
        case .flipBike:
            return BikeFraming(center: whole.center, radius: whole.radius * 1.05, facing: [0.75, 0, 1], elevation: 0.22)
        case .removeFrontWheel:
            return BikeFraming(center: rig.front + [0.2, -0.04, 0], radius: rig.wheelRadius + 0.3, facing: [0.3, 0, 1], elevation: 0.15)
        case .removeRearWheel:
            return BikeFraming(center: rig.rear + [-0.2, -0.04, 0], radius: rig.wheelRadius + 0.3, facing: [-0.2, 0, 1], elevation: 0.15)
        case .spinWheel:
            return BikeFraming(center: rig.front, radius: rig.wheelRadius + 0.08, facing: [0.15, 0, 1], elevation: 0.1)
        case .deflateTire:
            return BikeFraming(center: rig.valve + [0.02, 0.0, 0.02], radius: 0.26, facing: [0.4, 0, 1], elevation: 0.2)
        case .pumpTire:
            return BikeFraming(center: (rig.valve + pumpBase + [0, 0.66, 0]) / 2 + [-0.04, 0, 0], radius: 0.42, facing: [0.15, 0, 1], elevation: 0.12)
        case .leverTire:
            let (pivot, dir, _) = leverFrame
            return BikeFraming(center: pivot - dir * 0.07 + [0, 0, 0.04], radius: 0.27, facing: [0.55, 0, 1], elevation: 0.35)
        case .turnPedals:
            return BikeFraming(center: rig.bb + [-0.1, 0.04, 0], radius: 0.36, facing: [0.05, 0, 1], elevation: 0.12)
        case .oilChain:
            return BikeFraming(center: oilTarget + [0, 0.04, 0], radius: 0.16, facing: [-0.1, 0, 1], elevation: 0.22)
        case .wipeChain:
            return BikeFraming(center: clothPoint + [0, 0.02, 0], radius: 0.16, facing: [-0.1, 0, 1], elevation: 0.18)
        case .removeChain:
            return BikeFraming(center: rig.bb + [-0.06, 0, 0.05], radius: 0.21, facing: [0.5, 0, 1], elevation: 0.35)
        case .squeezeBrake:
            if rig.levers.isEmpty {
                return BikeFraming(center: mix(rig.bb, rig.rear, 0.5), radius: 0.45, facing: [0, 0, -1], elevation: 0.15)
            }
            let lever = brakeLever
            guard rig.brakeOnLeft else {
                // Fælgbremse: grebet og klodserne i samme billede.
                return BikeFraming(center: mix(lever.tip, rig.frontBrake, 0.5), radius: simd_length(lever.tip - rig.frontBrake) / 2 + 0.1, facing: [0.5, 0, 1], elevation: 0.2)
            }
            // Skive/rulle: klodserne ses ikke, så vis grebet tæt på.
            return BikeFraming(center: mix(lever.pivot, lever.tip, 0.5) + [0, 0.02, 0], radius: 0.14, facing: [-0.2, 0, lever.pivot.z > 0 ? 1 : -1], elevation: 0.5)
        case .replaceBrakePads:
            let pad = rig.pads.first.map { home($0.entity) } ?? rig.frontBrake
            return BikeFraming(center: mix(pad, rig.frontBrake, 0.4), radius: 0.12, facing: [0.6, 0, side], elevation: rig.brakeOnLeft ? 0.3 : 0.05)
        case .adjustCable:
            guard let barrel = rig.barrel else { return boltFraming(rig.bolts[.brakes]!) }
            return BikeFraming(center: barrel.tip + [0, 0.01, 0], radius: 0.12, facing: [-0.2, 0, 1], elevation: 0.3)
        case .shiftGears:
            if rig.derailleur != nil {
                // Kædegear: se kæden klatre op ad tandhjulene.
                return BikeFraming(center: rig.rear + [0.06, -0.03, rig.chainZ], radius: 0.2, facing: [-0.25, 0, 1], elevation: 0.25)
            }
            // Navgear: skiftet sker inde i navet, så vis drejegrebet.
            let grip = rig.shifter?.pivot ?? rig.barCenter
            return BikeFraming(center: grip + [0, -0.01, 0], radius: 0.13, facing: [-0.3, 0, 1], elevation: 0.35)
        case .moveSaddle:
            return BikeFraming(center: home(rig.saddle) + rig.seatDir * 0.1, radius: 0.22, facing: [-0.2, 0, 1], elevation: 0.12)
        case .tightenBolt, .loosenBolt:
            return boltFraming(bolt(for: highlight))
        case .alignHandlebar:
            return BikeFraming(center: rig.barCenter + [-0.04, -0.08, 0], radius: 0.36, facing: [-1, 0, 0.3], elevation: 0.8)
        case .switchLight:
            return BikeFraming(center: rig.frontLight + [0.14, -0.03, 0], radius: 0.25, facing: [0.8, 0, 1], elevation: 0.2)
        case .unscrewPedal:
            return BikeFraming(center: home(rig.pedals[0]) + [0, 0, 0.04], radius: 0.17, facing: [0.35, 0, 1], elevation: 0.3)
        case .inspect:
            guard let spot = highlight.flatMap({ spots[$0] }) else { return whole }
            return BikeFraming(center: spot.center, radius: max(spot.radius, 0.2) * 1.5, facing: spot.facing, elevation: 0.22)
        }
    }

    private func boltFraming(_ bolt: Bolt) -> BikeFraming {
        let a = bolt.axis
        if abs(a.y) > 0.7 {
            return BikeFraming(center: bolt.point + a * 0.02, radius: 0.12, facing: [0.4, 0, 1], elevation: 0.8)
        }
        return BikeFraming(center: bolt.point + a * 0.02, radius: 0.12, facing: [a.x + 0.4, 0, a.z], elevation: 0.3)
    }

    /// Skriv stillingen til tiden `t` (sekunder i loopet). nil = hvile.
    func apply(_ animation: StepAnimation?, t: Float, dt: Float, highlight: BikePart?) {
        let blending = blend < 1
        // Hvile (eller .inspect) og intet at bløde over: alt står allerede i hvile.
        if !blending, touched.isEmpty, animation == nil || animation == .inspect { return }

        // Nulstil kun målet for det forrige billede rørte; resten står allerede i hvile.
        let previous = touched
        for i in previous {
            target[i] = rest[i]
            targetAlpha[i] = restAlpha[i]
        }
        touched.removeAll(keepingCapacity: true)
        if let animation { pose(animation, t: t, highlight: highlight) }

        blend = min(1, blend + dt / 0.5)
        guard blending else {
            for i in previous where !touched.contains(i) { write(i, target[i], targetAlpha[i]) }
            for i in touched { write(i, target[i], targetAlpha[i]) }
            return
        }
        // Under overgangen kan alt være flyttet fra hvile, så alt blødes.
        let w = blend * blend * (3 - 2 * blend)
        for i in animated.indices {
            let (from, fromAlpha) = snapshot[i]
            var to = target[i]
            if w < 1, from != to {
                to.translation = simd_mix(from.translation, to.translation, P(repeating: w))
                to.rotation = simd_slerp(from.rotation, to.rotation, w)
                to.scale = simd_mix(from.scale, to.scale, P(repeating: w))
            }
            write(i, to, w < 1 ? fromAlpha + (targetAlpha[i] - fromAlpha) * w : targetAlpha[i])
        }
    }

    /// Skriv transform og opacitet til entity `i`, kun hvis de har ændret sig.
    private func write(_ i: Int, _ transform: Transform, _ a: Float) {
        let e = animated[i]
        if transform != written[i] {
            e.transform = transform
            written[i] = transform
        }
        alpha[i] = a
        let old = appliedAlpha[i]
        guard abs(a - old) > 0.002 || (a > 0.998) != (old > 0.998) else { return }
        appliedAlpha[i] = a
        if restAlpha[i] == 0 { e.isEnabled = a > 0.002 }
        if a > 0.998 {
            e.components.remove(OpacityComponent.self)
        } else {
            e.components.set(OpacityComponent(opacity: a))
        }
    }

    /// Husk den aktuelle stilling, så næste animation (eller hvile) blødes ind fra den.
    func beginTransition() {
        snapshot = animated.indices.map { (written[$0], alpha[$0]) }
        blend = 0
    }

    /// Målstillingen for et animeret entity; at skrive til den markerer entity'et som rørt i dette billede.
    private subscript(e: Entity) -> Transform {
        get { target[index[ObjectIdentifier(e)]!] }
        set {
            let i = index[ObjectIdentifier(e)]!
            target[i] = newValue
            touched.insert(i)
        }
    }

    private func pose(_ animation: StepAnimation, t: Float, highlight: BikePart?) {
        switch animation {
        case .flipBike:
            // Løft, vend om langs cyklens længdeakse, stå på sadel og styr; vend tilbage og start forfra.
            // (Ingen udtoning: gennemsigtighed ville sende hele cyklen gennem den blandede pass.)
            let p = ramp(t, 0.5, 2.4) - ramp(t, 3.0, 4.1)
            self[model].rotation = simd_quatf(angle: .pi * p, axis: [1, 0, 0])
            self[model].translation.y = sin(.pi * p) * 0.25

        case .removeFrontWheel, .removeRearWheel:
            let isFront = animation == .removeFrontWheel
            let wheel = isFront ? rig.frontWheel : rig.rearWheel
            let axle = isFront ? rig.front : rig.rear
            let nut = Bolt(point: axle + [0, 0, 0.064], axis: [0, 0, 1])
            let visible = shown(t, 0.1, 1.55)
            place(wrench, at: nut.point, axis: nut.axis, spin: 0.9 + 1.4 * ramp(t, 0.5, 1.25), out: 0.04 * (1 - ramp(t, 0.1, 0.45) + ramp(t, 1.25, 1.55)))
            fade(wrench, visible)
            showTurn(at: nut.point + [0, 0, 0.012], axis: nut.axis, clockwise: false, radius: 0.08, opacity: shown(t, 0.45, 1.4))
            // Ned ud af gaflen, frem/tilbage, hold, og på igen.
            let down = ramp(t, 1.55, 1.95) - ramp(t, 3.2, 3.6)
            let away = ramp(t, 1.8, 2.5) - ramp(t, 2.9, 3.4)
            let dir: Float = isFront ? 1 : -1
            self[wheel].translation += [dir * 0.4 * away, -0.12 * down, 0]
            showMove(from: axle + [dir * 0.1, -0.05, 0.12], direction: [dir, -0.25, 0], length: 0.16, opacity: shown(t, 1.6, 2.6))

        case .spinWheel:
            self[rig.frontWheel].rotation = simd_quatf(angle: -2 * .pi * ramp(t, 0.2, 3.2), axis: [0, 0, 1])
            showTurn(at: rig.front + [0, 0, 0.09], axis: [0, 0, 1], clockwise: true, radius: 0.15, opacity: shown(t, 0.1, 3.3))

        case .deflateTire:
            softenTire(ramp(t, 0.5, 2.6) * (1 - ramp(t, 3.2, 3.55)))
            let out = simd_normalize(rig.valveDir + [0.3, 0, 0.9])
            showMove(from: rig.valve + rig.valveDir * 0.01, direction: rig.valveDir, length: 0.07, opacity: shown(t, 0.4, 2.7))
            for (i, puff) in puffs.enumerated() {
                let u = (t - 0.5 - Float(i) * 0.5) / 0.9
                guard (0...1).contains(u) else { continue }
                self[puff].translation = rig.valve + rig.valveDir * 0.005 + out * (0.01 + 0.06 * u)
                self[puff].scale = P(repeating: 1 + 2.5 * u)
                fade(puff, sin(u * .pi) * 0.85)
            }

        case .pumpTire:
            let strokes = (0..<3).map { k -> Float in
                let s = 0.55 + Float(k) * 0.85
                return ramp(t, s, s + 0.38) - ramp(t, s + 0.42, s + 0.8)
            }
            let filled = (0..<3).reduce(Float(0)) { sum, k in sum + ramp(t, 0.55 + Float(k) * 0.85, 0.95 + Float(k) * 0.85) } / 3
            softenTire(max(1 - filled, ramp(t, 3.35, 3.8)))
            fade(pump, shown(t, 0, 3.6, fade: 0.35))
            self[pumpHandle].translation.y -= 0.11 * strokes.reduce(0, +)
            // Luften løber gennem slangen ind i ventilen ved hvert tryk.
            for k in 0..<3 {
                let u = (t - 0.6 - Float(k) * 0.85) / 0.55
                guard (0...1).contains(u) else { continue }
                let x = u * Float(hose.count - 1)
                let i = min(Int(x), hose.count - 2)
                self[puffs[k]].translation = mix(hose[i], hose[i + 1], x - Float(i))
                self[puffs[k]].scale = P(repeating: 2)
                fade(puffs[k], sin(u * .pi))
            }
            showMove(from: pumpBase + [0, 0.66, 0.05], direction: [0, -1, 0], length: 0.1, opacity: shown(t, 0.45, 2.9) * 0.9)

        case .leverTire:
            let (pivot, dir, tangent) = leverFrame
            let a = 0.25 + 2.3 * ramp(t, 0.7, 1.7)
            let handle = dir * cos(a) + P(0, 0, 1) * sin(a)
            self[tireLever].translation = pivot + dir * 0.04 * (1 - ramp(t, 0.1, 0.5))
            self[tireLever].rotation = simd_quatf(simd_float3x3(columns: (tangent, handle, simd_cross(tangent, handle))))
            fade(tireLever, shown(t, 0.1, 2.9))
            // Pilen ligger i hjulets plan: "fra udad til ind mod egerne".
            showTurn(at: pivot + [0, 0, 0.06], axis: [0, 0, 1], clockwise: true, radius: 0.09, opacity: shown(t, 0.55, 1.9))
            // Dækket vipper ud over fælgkanten ved dækjernet.
            if let tire = rig.frontTire {
                let lift = -0.11 * ramp(t, 0.85, 1.7) * (1 - ramp(t, 2.8, 3.4))
                rotate(tire, by: simd_quatf(angle: lift, axis: tangent), about: rig.front - dir * rig.wheelRadius)
            }

        case .turnPedals:
            pedal(2 * .pi * ramp(t, 0.3, 3.2))
            showTurn(at: rig.bb + [0, 0, 0.16], axis: [0, 0, 1], clockwise: false, radius: 0.215, opacity: shown(t, 0.2, 3.3))

        case .oilChain:
            pedal(2 * .pi * ramp(t, 0.2, 3.7))
            let tip = oilTarget + [0, 0.075, 0]
            place(bottle, at: tip, axis: simd_normalize([0.35, 1, 0.3]))
            fade(bottle, shown(t, 0, 3.6))
            for d: Float in [0.9, 1.75, 2.6] {
                let squeeze = ramp(t, d - 0.35, d - 0.1) - ramp(t, d, d + 0.25)
                self[bottleBody].scale = [1 - 0.12 * squeeze, 1, 1 - 0.12 * squeeze]
                if (d - 0.3...d).contains(t) {
                    self[drop].translation = tip
                    self[drop].scale = P(repeating: ramp(t, d - 0.3, d))
                    fade(drop, 1)
                } else if (d...d + 0.3).contains(t) {
                    let u = (t - d) / 0.3
                    self[drop].translation = tip - [0, 0.068 * u * u, 0]
                    self[drop].scale = [1 - 0.3 * u, 1 + 0.4 * u, 1 - 0.3 * u]
                    fade(drop, 1 - ramp(u, 0.85, 1))
                }
                if squeeze > 0 { break }
            }
            showRun(opacity: shown(t, 0.3, 3.5))

        case .wipeChain:
            pedal(2 * .pi * ramp(t, 0.3, 3.3))
            self[cloth].translation = clothPoint + [0.006 * sin(t * 11), 0.002 * sin(t * 7), 0]
            self[cloth].scale = [1, 0.92 + 0.06 * sin(t * 9), 1]
            fade(cloth, shown(t, 0, 3.5, fade: 0.35))
            showRun(opacity: shown(t, 0.4, 3.3))

        case .removeChain:
            let lift = ramp(t, 0.3, 1.1) - ramp(t, 2.7, 3.4)
            let drape = ramp(t, 1.0, 1.8) - ramp(t, 2.4, 3.0)
            let mid = (rig.bb.x + rig.rear.x) / 2, front = rig.bb.x + rig.chain.ringR
            layOutChain(offset: 0) { p in
                let w = pow(min(max((p.x - mid) / (front - mid), 0), 1), 1.5)
                return [0, -0.07 * drape * w, 0.035 * lift * w]
            }
            showMove(from: rig.bb + [0.05, rig.chain.ringR * 0.6, rig.chainZ + 0.02], direction: simd_normalize([0.2, -0.4, 1]), length: 0.06, opacity: shown(t, 0.2, 1.9))

        case .squeezeBrake:
            squeezeBrake(t)

        case .replaceBrakePads:
            let isNew = t > 1.3
            let amount = isNew ? 1 - ramp(t, 1.6, 2.4) : ramp(t, 0.4, 1.1)
            for pad in rig.pads {
                self[pad.entity].translation += pad.slide * 0.06 * amount
                fade(pad.entity, isNew ? ramp(t, 1.35, 1.7) : 1 - ramp(t, 0.85, 1.25))
                setMaterial(pad.entity, isNew ? newPad : wornPad)
            }
            if let pad = rig.pads.first {
                let p = self[pad.entity].translation + pad.slide * 0.02
                showMove(from: isNew ? p + pad.slide * 0.09 : p, direction: isNew ? -pad.slide : pad.slide, length: 0.06,
                         opacity: isNew ? shown(t, 1.55, 2.5) : shown(t, 0.3, 1.2))
            }

        case .adjustCable:
            let target = rig.barrel ?? BikeRig.Lever(entity: Entity(), pivot: rig.bolts[.brakes]!.point, tip: rig.bolts[.brakes]!.point, axis: rig.bolts[.brakes]!.axis)
            let spin = 1.5 * .pi * ramp(t, 0.6, 2.3)
            if let barrel = rig.barrel { self[barrel.entity].rotation = simd_quatf(angle: spin, axis: barrel.axis) }
            place(screwdriver, at: target.tip, axis: target.axis, spin: spin, out: 0.03 * (1 - ramp(t, 0.1, 0.5) + ramp(t, 2.4, 2.8)))
            fade(screwdriver, shown(t, 0.1, 2.8))
            showTurn(at: target.tip + target.axis * 0.015, axis: target.axis, clockwise: false, radius: 0.035, opacity: shown(t, 0.5, 2.4))

        case .shiftGears:
            shiftGears(t)

        case .moveSaddle:
            let up = ramp(t, 0.3, 1.3) - ramp(t, 1.9, 2.9)
            self[rig.saddle].translation += rig.seatDir * 0.075 * up
            let base = self[rig.saddle].translation + [0, 0, 0.07]
            showMove(from: t < 1.6 ? base : base + rig.seatDir * 0.16, direction: t < 1.6 ? rig.seatDir : -rig.seatDir, length: 0.09,
                     opacity: t < 1.6 ? shown(t, 0.2, 1.5) : shown(t, 1.75, 3.0))

        case .tightenBolt, .loosenBolt:
            let tighten = animation == .tightenBolt
            let bolt = bolt(for: highlight)
            place(hexKey, at: bolt.point, axis: bolt.axis, spin: (tighten ? -1.9 : 1.9) * ramp(t, 0.7, 2.0) + (tighten ? 1.2 : -0.4),
                  out: 0.04 * (1 - ramp(t, 0.15, 0.55) + ramp(t, 2.3, 2.7)))
            fade(hexKey, shown(t, 0.15, 2.75))
            showTurn(at: bolt.point + bolt.axis * 0.03, axis: bolt.axis, clockwise: tighten, radius: 0.055, opacity: shown(t, 0.55, 2.2))

        case .alignHandlebar:
            // Skævt → lige, og drej skævt igen til sidst, så loopet er sømløst uden at tone styret ud.
            let angle = 0.38 * (1 - ramp(t, 0.7, 2.0) + ramp(t, 2.7, 3.5))
            self[rig.handlebar].rotation = simd_quatf(angle: angle, axis: rig.steer)
            showTurn(at: home(rig.handlebar) + rig.steer * 0.12, axis: rig.steer, clockwise: true, radius: 0.13, opacity: shown(t, 0.55, 2.1))

        case .switchLight:
            let on = ramp(t, 0.85, 1.0) - ramp(t, 2.85, 3.0)
            let level = min(Int(on * 8), 7)
            for (i, lens) in rig.lenses.enumerated() {
                setMaterial(lens, on < 0.01 ? lampOff : i == 0 ? Self.frontLit[level] : Self.rearLit[level])
            }
            self[beam].translation = rig.frontLight + [0.035, 0, 0]
            fade(beam, on)
            showMove(from: rig.frontLight + [-0.01, 0.11, 0], direction: [0, -1, 0], length: 0.07, opacity: shown(t, 0.2, 1.05))

        case .unscrewPedal:
            let spindle = home(rig.pedals[0])
            let jaw = spindle + [0, 0, 0.016]
            place(wrench, at: jaw, axis: [0, 0, 1], spin: 1.3 * ramp(t, 0.45, 1.3), out: 0.03 * (1 - ramp(t, 0.1, 0.4)))
            fade(wrench, shown(t, 0.1, 1.6))
            showTurn(at: jaw + [0, 0, 0.012], axis: [0, 0, 1], clockwise: false, radius: 0.045, opacity: shown(t, 0.4, 2.7))
            let u = ramp(t, 1.6, 2.8)
            self[rig.pedals[0]].rotation = simd_quatf(angle: 4 * .pi * u, axis: [0, 0, 1])
            self[rig.pedals[0]].translation += [0, 0, 0.07 * u]
            fade(rig.pedals[0], ramp(t, 0, 0.3) * (1 - ramp(t, 3.0, 3.4)))

        case .inspect:
            break
        }
    }

    // MARK: - Fælles bevægelser

    private var brakeLever: BikeRig.Lever { rig.levers[0] }

    private func squeezeBrake(_ t: Float) {
        // Hjulet snurrer, grebet trykkes, klodserne tager fat og hjulet stopper (i alt én omgang, så loopet er sømløst).
        let omega: Float = 2 * .pi / 1.2
        let angle = t < 1.0 ? omega * t : omega * 1.0 + omega * min(t - 1, 0.4) - omega * pow(min(t - 1, 0.4), 2) / 0.8
        let squeeze = ramp(t, 0.8, 1.05) - ramp(t, 2.2, 2.6)
        if rig.levers.isEmpty {
            // Fodbremse: træd lidt baglæns, baghjulet stopper.
            self[rig.rearWheel].rotation = simd_quatf(angle: -angle, axis: [0, 0, 1])
            pedal(0.6 * squeeze)
            showTurn(at: rig.bb + [0, 0, -0.14], axis: [0, 0, -1], clockwise: true, radius: 0.2, opacity: shown(t, 0.6, 1.6))
            return
        }
        self[rig.frontWheel].rotation = simd_quatf(angle: -angle, axis: [0, 0, 1])
        for lever in rig.levers { self[lever.entity].rotation = simd_quatf(angle: 0.4 * squeeze, axis: lever.axis) }
        for pad in rig.pads { self[pad.entity].translation += pad.squeeze * squeeze }
        let lever = brakeLever
        let arm = lever.tip - lever.pivot
        let dir = simd_normalize(simd_quatf(angle: 0.4, axis: lever.axis).act(arm) - arm)
        showMove(from: mix(lever.pivot, lever.tip, 0.7) - dir * 0.06, direction: dir, length: rig.brakeOnLeft ? 0.045 : 0.07, opacity: shown(t, 0.45, 1.4))
    }

    private func shiftGears(_ t: Float) {
        // Træd fremad; gearet skifter op og ned igen.
        let theta = -2 * Float.pi * ramp(t, 0.2, 3.4)
        let shift = ramp(t, 1.0, 1.4) - ramp(t, 2.4, 2.8)
        if let shifter = rig.shifter {
            let click = rig.derailleur == nil ? shift : (ramp(t, 0.85, 1.0) - ramp(t, 1.1, 1.3)) + (ramp(t, 2.25, 2.4) - ramp(t, 2.5, 2.7))
            self[shifter.entity].rotation = simd_quatf(angle: 0.45 * click, axis: shifter.axis)
            showTurn(at: shifter.tip, axis: shifter.axis, clockwise: false, radius: 0.04, opacity: shown(t, 0.6, 2.4))
        }
        var cogR = rig.chain.cogR
        if let derailleur = rig.derailleur {
            cogR += 0.022 * shift
            self[derailleur].translation += [0, 0.015, -0.03] * shift
            showMove(from: rig.rear + [0.0, -0.13, rig.chainZ + 0.03], direction: [0, 0.3, -1], length: 0.05, opacity: shown(t, 0.9, 1.7))
        }
        pedal(theta, cogR: cogR, drivesWheel: true)
    }

    /// Drej kranken `theta` radianer om z (positiv = baglæns); kæden og tandhjulene følger med, pedalerne holdes vandrette.
    private func pedal(_ theta: Float, cogR: Float? = nil, drivesWheel: Bool = false) {
        self[rig.crank].rotation = simd_quatf(angle: theta, axis: [0, 0, 1])
        for p in rig.pedals { self[p].rotation = simd_quatf(angle: -theta, axis: [0, 0, 1]) }
        let s = theta * chainPerRadian
        let r = cogR ?? rig.chain.cogR
        self[rig.cassette].rotation = simd_quatf(angle: s / r, axis: [0, 0, 1])
        if drivesWheel { self[rig.rearWheel].rotation = simd_quatf(angle: s / r, axis: [0, 0, 1]) }
        layOutChain(offset: s, cogR: r)
    }

    private func layOutChain(offset s: Float, cogR: Float? = nil, displace: ((P) -> P)? = nil) {
        var loop = rig.chain
        if let cogR { loop.cogR = cogR }
        let pitch = loop.length / Float(rig.links.count)
        for (i, link) in rig.links.enumerated() {
            let (p, angle) = loop.point(at: s + Float(i) * pitch)
            let pos = P(p.x, p.y, rig.chainZ)
            self[link].translation = pos + (displace?(pos) ?? .zero)
            self[link].rotation = simd_quatf(angle: angle, axis: [0, 0, 1])
        }
    }

    /// Tryk dækket flat (0 = pumpet, 1 = fladt).
    private func softenTire(_ amount: Float) {
        guard let tire = rig.frontTire, let i = index[ObjectIdentifier(tire)] else { return }
        self[tire].scale = simd_mix(rest[i].scale, P(0.955, 0.955, 0.6), P(repeating: amount))
    }

    /// Pil langs kædens top, i den retning den kører (baglæns trædning).
    private func showRun(opacity: Float) {
        let top = rig.chain.point(at: rig.chain.straight * 0.3)
        let next = rig.chain.point(at: rig.chain.straight * 0.3 + 0.01)
        let dir = simd_normalize(next.0 - top.0)
        showMove(from: [top.0.x, top.0.y + 0.028, rig.chainZ], direction: [dir.x, dir.y, 0], length: 0.07, opacity: opacity)
    }

    // MARK: - Ankerpunkter

    private func bolt(for part: BikePart?) -> Bolt {
        rig.bolts[part ?? .handlebar] ?? rig.bolts[.handlebar]!
    }

    private var pumpBase: P { [rig.front.x + 0.46, 0, 0.12] }

    /// Dækjernets drejepunkt på fælgkanten, retning ud fra navet og fælgens tangent.
    private var leverFrame: (P, P, P) {
        let a: Float = 50 * .pi / 180
        let dir = P(cos(a), sin(a), 0)
        let pivot = rig.front + dir * (rig.wheelRadius - rig.tireWidth + 0.004) + [0, 0, rig.rimDepth / 2 + 0.004]
        return (pivot, dir, P(-sin(a), cos(a), 0))
    }

    private var oilTarget: P {
        let (p, _) = rig.chain.point(at: rig.chain.straight * 0.55)
        return [p.x, p.y, rig.chainZ]
    }

    private var clothPoint: P {
        let (p, _) = rig.chain.point(at: rig.chain.straight * 1.5 + rig.chain.cogArc)
        return [p.x, p.y, rig.chainZ]
    }

    // MARK: - Hjælpere

    /// Hvileposition (i forælderens koordinater).
    private func home(_ e: Entity) -> P { rest[index[ObjectIdentifier(e)]!].translation }

    private func fade(_ e: Entity, _ value: Float) {
        guard let i = index[ObjectIdentifier(e)] else { return }
        alpha[i] = value
    }

    /// Stil et værktøj (bygget langs lokal y) på `point` langs `axis`, drejet `spin` om aksen og trukket `out` ud.
    private func place(_ tool: Entity, at point: P, axis: P, spin: Float = 0, out: Float = 0) {
        self[tool].translation = point + axis * out
        self[tool].rotation = simd_quatf(from: [0, 1, 0], to: axis) * simd_quatf(angle: spin, axis: [0, 1, 0])
    }

    private func rotate(_ e: Entity, by q: simd_quatf, about point: P) {
        var tr = self[e]
        tr.translation = point + q.act(tr.translation - point)
        tr.rotation = q * tr.rotation
        self[e] = tr
    }

    private func showTurn(at point: P, axis: P, clockwise: Bool, radius: Float, opacity: Float) {
        place(turnArrow, at: point, axis: clockwise ? -axis : axis)
        self[turnArrow].scale = P(repeating: radius)
        fade(turnArrow, opacity)
    }

    private func showMove(from point: P, direction: P, length: Float, opacity: Float) {
        place(moveArrow, at: point, axis: simd_normalize(direction))
        self[moveArrow].scale = P(repeating: length)
        fade(moveArrow, opacity)
    }

    // MARK: - Værktøj

    func setColors(accent: UIColor, dark: Bool) {
        newPad = BikeBuilder.highlight(accent, glow: 0.6)
        // Lidt mørkere end den fremhævede del, så værktøjet kan skelnes fra den.
        var h: CGFloat = 0, sat: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        accent.getHue(&h, saturation: &sat, brightness: &b, alpha: &a)
        let tool = BikeBuilder.highlight(UIColor(hue: h, saturation: sat, brightness: b * 0.72, alpha: 1), glow: 0.15)
        for part in toolParts { part.model?.materials = [tool] }
        for part in arrowParts { part.model?.materials = [UnlitMaterial(color: accent)] }
        var puff = UnlitMaterial(color: UIColor(white: dark ? 0.9 : 0.55, alpha: 1))
        puff.blending = .transparent(opacity: 0.7)
        for part in puffParts { part.model?.materials = [puff] }
    }

    /// Sæt et materiale, kun når det skifter. Scenens puls/fremhævning kan have skrevet et andet materiale på
    /// entity'et siden, så sammenlign med det, der faktisk sidder der (lysstyrke og ruhed skelner vores varianter).
    private func setMaterial(_ e: ModelEntity, _ m: PhysicallyBasedMaterial) {
        if let current = e.model?.materials.first as? PhysicallyBasedMaterial,
           current.emissiveIntensity == m.emissiveIntensity, current.roughness.scale == m.roughness.scale { return }
        e.model?.materials = [m]
    }

    /// Lav-poly UV-kugle (10×6 segmenter, 120 trekanter); `generateSphere` giver ca. 8.000.
    private static func lowSphere(radius r: Float) -> MeshResource {
        let segments = 10, rings = 6
        var positions: [P] = [], normals: [P] = [], indices: [UInt32] = []
        for j in 0...rings {
            let v = Float(j) / Float(rings) * .pi
            for i in 0...segments {
                let u = Float(i) / Float(segments) * 2 * .pi
                let n = P(sin(v) * cos(u), cos(v), sin(v) * sin(u))
                positions.append(n * r)
                normals.append(n)
            }
        }
        let row = UInt32(segments + 1)
        for j in 0..<UInt32(rings) {
            for i in 0..<UInt32(segments) {
                let a = j * row + i, b = a + row
                indices += [a, a + 1, b, a + 1, b + 1, b]
            }
        }
        var d = MeshDescriptor(name: "lowSphere")
        d.positions = MeshBuffers.Positions(positions)
        d.normals = MeshBuffers.Normals(normals)
        d.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [d])) ?? .generateSphere(radius: r)
    }

    private func buildTools() {
        let neutral = pbr(UIColor(white: 0.2, alpha: 1), roughness: 0.5)
        let steel = pbr(UIColor(white: 0.75, alpha: 1), roughness: 0.25, metallic: 1)

        func part(_ mesh: MeshResource, _ parent: Entity, at p: P, rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0]), accent: Bool = true, material: (any RealityKit.Material)? = nil) {
            let e = ModelEntity(mesh: mesh, materials: [material ?? neutral])
            e.position = p - rotation.act([0, 0, mesh.bounds.center.z])
            e.orientation = rotation
            parent.addChild(e)
            if accent, material == nil { toolParts.append(e) }
        }
        func rod(_ a: P, _ b: P, _ r: Float, _ parent: Entity, accent: Bool = true, material: (any RealityKit.Material)? = nil) {
            let d = b - a
            part(.generateCylinder(height: simd_length(d), radius: r), parent, at: (a + b) / 2, rotation: simd_quatf(from: [0, 1, 0], to: simd_normalize(d)), accent: accent, material: material)
        }
        let flat = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])   // xy-planet → xz-planet (akse z → y)

        // Unbrakonøgle: kort ben i skruen, langt ben vinkelret.
        rod([0, 0, 0], [0, 0.03, 0], 0.0045, hexKey)
        part(Self.lowSphere(radius: 0.0045), hexKey, at: [0, 0.03, 0])
        rod([0, 0.03, 0], [0.09, 0.03, 0], 0.0045, hexKey)

        // Gaffelnøgle: åben kæbe om akslen, skaft bagud.
        part(BikeBuilder.ring(outer: 0.026, inner: 0.012, depth: 0.007, chamfer: 0.001, from: 40, to: 320), wrench, at: .zero, rotation: flat)
        part(.generateBox(size: [0.19, 0.007, 0.026]), wrench, at: [-0.115, 0, 0])

        // Skruetrækker: tynd stålklinge, tykt skaft.
        rod([0, 0, 0], [0, 0.035, 0], 0.0022, screwdriver, material: steel)
        rod([0, 0.035, 0], [0, 0.09, 0], 0.009, screwdriver)
        part(Self.lowSphere(radius: 0.009), screwdriver, at: [0, 0.09, 0])

        // Dækjern: flad spatel med krog i enden.
        part(.generateBox(size: [0.026, 0.15, 0.006]), tireLever, at: [0, 0.07, 0])
        part(.generateBox(size: [0.026, 0.016, 0.006]), tireLever, at: [0, -0.003, -0.005], rotation: simd_quatf(angle: -0.8, axis: [1, 0, 0]))

        // Standerpumpe ved forhjulet med slange til ventilen.
        let base = pumpBase
        part(.generateBox(size: [0.16, 0.012, 0.07]), pump, at: base + [0, 0.006, 0], accent: false)
        rod(base + [0, 0.012, 0], base + [0, 0.5, 0], 0.022, pump)
        pump.addChild(pumpHandle)
        rod(base + [0, 0.42, 0], base + [0, 0.63, 0], 0.005, pumpHandle, material: steel)
        rod(base + [0, 0.63, -0.08], base + [0, 0.63, 0.08], 0.012, pumpHandle, accent: false)
        let head = rig.valve + rig.valveDir * 0.012
        // Få led: 6 cylindre med lav-poly kugler i knæk (luftpuffene følger samme linje).
        hose = (0...6).map { i -> P in
            let u = Float(i) / 6
            let p0 = base + [-0.022, 0.05, 0], p1 = base + [-0.12, 0.0, 0], p2 = head + rig.valveDir * 0.06 + [0.02, 0, 0.1], p3 = head + rig.valveDir * 0.012
            let v = 1 - u
            return v * v * v * p0 + 3 * v * v * u * p1 + 3 * v * u * u * p2 + u * u * u * p3
        }
        for (a, b) in zip(hose, hose.dropFirst()) { rod(a, b, 0.0042, pump, accent: false) }
        for p in hose.dropFirst().dropLast() { part(Self.lowSphere(radius: 0.0042), pump, at: p, accent: false) }
        rod(head - rig.valveDir * 0.01, head + rig.valveDir * 0.02, 0.008, pump)

        // Olieflaske: dyse i origo, krop opad.
        rod([0, 0, 0], [0, 0.03, 0], 0.0025, bottle)
        bottle.addChild(bottleBody)
        part(.generateCone(height: 0.025, radius: 0.018), bottleBody, at: [0, 0.042, 0], rotation: simd_quatf(angle: .pi, axis: [1, 0, 0]))
        rod([0, 0.054, 0], [0, 0.12, 0], 0.02, bottleBody)
        part(Self.lowSphere(radius: 0.005), drop, at: .zero, material: pbr(UIColor(red: 0.85, green: 0.62, blue: 0.15, alpha: 1), roughness: 0.1))

        // Klud om kædens nederste part.
        part(.generateBox(size: [0.075, 0.042, 0.05]), cloth, at: .zero)

        // Lyskegle foran forlygten.
        var light = UnlitMaterial(color: UIColor(red: 1, green: 0.8, blue: 0.3, alpha: 1))
        light.blending = .transparent(opacity: 0.4)
        part(.generateCone(height: 0.55, radius: 0.15), beam, at: [0.275, 0, 0], rotation: simd_quatf(angle: .pi / 2, axis: [0, 0, 1]), accent: false, material: light)

        for puff in puffs {
            let e = ModelEntity(mesh: Self.lowSphere(radius: 0.007), materials: [])
            puff.addChild(e)
            puffParts.append(e)
        }

        // Buet pil (enhedsradius, mod uret om +y) og lige pil (enhedslængde langs +y).
        func arrow(_ mesh: MeshResource, _ parent: Entity, at p: P, rotation: simd_quatf) {
            let e = ModelEntity(mesh: mesh, materials: [])
            e.position = p - rotation.act([0, 0, mesh.bounds.center.z])
            e.orientation = rotation
            parent.addChild(e)
            arrowParts.append(e)
        }
        let a1: Float = 290 * .pi / 180
        let turn = Entity()
        turn.orientation = flat
        turnArrow.addChild(turn)
        arrow(BikeBuilder.ring(outer: 1.035, inner: 0.965, depth: 0.07, chamfer: 0.02, from: 20, to: 280), turn, at: .zero, rotation: simd_quatf(angle: 0, axis: [0, 0, 1]))
        let end = P(cos(a1), sin(a1), 0)
        arrow(.generateCone(height: 0.3, radius: 0.12), turn, at: end * 1 + P(-sin(a1), cos(a1), 0) * -0.05, rotation: simd_quatf(from: [0, 1, 0], to: [-sin(a1), cos(a1), 0]))
        arrow(.generateCylinder(height: 0.72, radius: 0.045), moveArrow, at: [0, 0.36, 0], rotation: simd_quatf(angle: 0, axis: [0, 1, 0]))
        arrow(.generateCone(height: 0.3, radius: 0.13), moveArrow, at: [0, 0.85, 0], rotation: simd_quatf(angle: 0, axis: [0, 1, 0]))
    }
}

// MARK: - Tid

/// 0 før `a`, 1 efter `b`, blød S-kurve imellem.
private func ramp(_ t: Float, _ a: Float, _ b: Float) -> Float {
    let x = min(max((t - a) / (b - a), 0), 1)
    return x * x * (3 - 2 * x)
}

/// Synlighed: toner ind fra `a`, ud til `b`.
private func shown(_ t: Float, _ a: Float, _ b: Float, fade: Float = 0.3) -> Float {
    ramp(t, a, a + fade) * (1 - ramp(t, b - fade, b))
}

private func mix(_ a: P, _ b: P, _ t: Float) -> P { a + (b - a) * t }
