import RealityKit
import SwiftUI

/// En mesh i cyklen og den del, den hører til (nil = neutral detalje som fælg, skærm, lad).
struct Bike3DPiece {
    let entity: ModelEntity
    let part: BikePart?
    let material: any RealityKit.Material
}

/// Hvor en del sidder: hotspot-punkt, hvad kameraet rammer ind ved fokus, og hvilken side der skal vende mod beskueren.
struct PartSpot {
    var marker: SIMD3<Float>
    var center: SIMD3<Float>
    var radius: Float
    var facing: SIMD3<Float>
}

/// Et sted hvor et værktøj griber fat: punktet og aksen der peger ud af skruehovedet (mod værktøjet).
struct Bolt {
    var point: SIMD3<Float>
    var axis: SIMD3<Float>
}

/// Bevægelige grupper i cyklen og de ankerpunkter animationerne bruger. Alle punkter i cyklens koordinater i hvile.
/// Hver rig-entity sidder i sit drejepunkt, så `orientation` drejer om det og `position` flytter det.
struct BikeRig {
    struct Lever {
        let entity: Entity
        let pivot: SIMD3<Float>
        let tip: SIMD3<Float>
        let axis: SIMD3<Float>
    }
    struct Pad {
        let entity: ModelEntity
        /// Forskydning når bremsen tager fat.
        let squeeze: SIMD3<Float>
        /// Retning klodsen trækkes ud af holderen.
        let slide: SIMD3<Float>
    }

    var frontWheel = Entity(), rearWheel = Entity()
    var frontTire: ModelEntity?
    /// Tandhjul bagpå (drejer med kæden, også når baghjulet står stille).
    var cassette = Entity()
    var crank = Entity()
    /// [højre, venstre]
    var pedals: [Entity] = []
    var saddle = Entity()
    var seatDir = SIMD3<Float>(0, 1, 0)
    var handlebar = Entity()
    var barCenter = SIMD3<Float>.zero
    var steer = SIMD3<Float>(0, 1, 0)
    /// [højre, venstre]; tom ved fodbremse.
    var levers: [Lever] = []
    var shifter: Lever?
    var derailleur: Entity?
    var barrel: Lever?
    var pads: [Pad] = []
    var frontBrake = SIMD3<Float>.zero
    /// Fremhæves på venstre side (skive-, rulle- og fodbremser sidder der).
    var brakeOnLeft = false
    var lenses: [ModelEntity] = []
    var frontLight = SIMD3<Float>.zero
    var links: [ModelEntity] = []
    var chain = ChainLoop(ring: .zero, cog: .zero, ringR: 0.1, cogR: 0.04)
    var chainZ: Float = 0.075
    var bb = SIMD3<Float>.zero
    var front = SIMD3<Float>.zero, rear = SIMD3<Float>.zero
    var wheelRadius: Float = 0.34, tireWidth: Float = 0.04, rimDepth: Float = 0.02
    /// Ventilens spids (hvor pumpen sættes på) og retningen ud af ventilen.
    var valve = SIMD3<Float>.zero
    var valveDir = SIMD3<Float>(0, -1, 0)
    var bolts: [BikePart: Bolt] = [:]
}

/// Kædens forløb i xy-planet: øverste part, rundt om tandhjulet, nederste part, rundt om klingen.
/// s vokser i den retning toppen bevæger sig bagud (= når man træder baglæns).
struct ChainLoop {
    var ring: SIMD2<Float>, cog: SIMD2<Float>, ringR: Float, cogR: Float

    private var geometry: (u: SIMD2<Float>, n: SIMD2<Float>, phi: Float, straight: Float) {
        let d = simd_length(cog - ring)
        let u = (cog - ring) / d
        let phi = asin((ringR - cogR) / d)
        return (u, SIMD2(u.y, -u.x), phi, d * cos(phi))
    }

    /// Længden af én lige part og af buen om tandhjulet.
    var straight: Float { geometry.straight }
    var cogArc: Float { cogR * (.pi - 2 * geometry.phi) }

    var length: Float {
        let g = geometry
        return 2 * g.straight + cogR * (.pi - 2 * g.phi) + ringR * (.pi + 2 * g.phi)
    }

    /// Punkt og tangentvinkel s meter langs kæden.
    func point(at s: Float) -> (SIMD2<Float>, Float) {
        let (u, n, phi, straight) = geometry
        let wTop = n * cos(phi) + u * sin(phi), wBottom = -n * cos(phi) + u * sin(phi)
        let base = atan2(n.y, n.x)
        let cogArc = cogR * (.pi - 2 * phi), ringArc = ringR * (.pi + 2 * phi)
        var s = s.truncatingRemainder(dividingBy: length)
        if s < 0 { s += length }
        let top = u * cos(phi) - n * sin(phi), bottom = -(u * cos(phi) + n * sin(phi))
        if s < straight { return (ring + ringR * wTop + top * s, atan2(top.y, top.x)) }
        s -= straight
        if s < cogArc {
            let a = base + phi + s / cogR
            return (cog + cogR * SIMD2(cos(a), sin(a)), a + .pi / 2)
        }
        s -= cogArc
        if s < straight { return (cog + cogR * wBottom + bottom * s, atan2(bottom.y, bottom.x)) }
        s -= straight
        let a = base + .pi - phi + min(s, ringArc) / ringR
        return (ring + ringR * SIMD2(cos(a), sin(a)), a + .pi / 2)
    }
}

private typealias P = SIMD3<Float>

/// Bygger en stiliseret cykel af primitive meshes.
/// Koordinater i meter: x = fremad, y = op, z = cyklens højre side (kædesiden).
final class BikeBuilder {
    let root = Entity()
    private(set) var pieces: [Bike3DPiece] = []
    private(set) var spots: [BikePart: PartSpot] = [:]
    private(set) var rig = BikeRig()
    /// Hvor nye meshes hænges på: roden eller en rig.
    private var parent: Entity
    private let bike: Bike

    private let paint: PhysicallyBasedMaterial
    private let rubber = pbr(UIColor(white: 0.11, alpha: 1), roughness: 0.85)
    private let metal = pbr(UIColor(white: 0.78, alpha: 1), roughness: 0.25, metallic: 1)
    private let darkMetal = pbr(UIColor(white: 0.22, alpha: 1), roughness: 0.4, metallic: 0.7)
    private let leather = pbr(UIColor(white: 0.16, alpha: 1), roughness: 0.6)
    private let wood = pbr(UIColor(red: 0.80, green: 0.64, blue: 0.45, alpha: 1), roughness: 0.7)
    private let frontLamp = emissive(UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1))
    private let rearLamp = emissive(.systemRed)

    init(bike: Bike) {
        self.bike = bike
        parent = root
        paint = pbr(uiColor(hex: bike.colorHex), roughness: 0.3, clearcoat: 1)
    }

    // MARK: - Geometri

    func build() -> Entity {
        let type = bike.type
        let upright = type == .city || type == .electric || type == .cargo
        let mtb = type == .mountain

        let rearR: Float = mtb ? 0.36 : 0.34
        let frontR: Float = type == .cargo ? 0.25 : rearR
        let tire: Float = switch type {
        case .road: 0.026
        case .mountain: 0.065
        default: 0.042
        }
        let r: Float = switch type {
        case .road: 0.015
        case .mountain: 0.024
        default: 0.02
        }

        let rear = P(mtb ? -0.55 : -0.52, rearR, 0)
        let bb = P(-0.06, 0.29, 0)
        let seat = P(-0.21, mtb ? 0.80 : 0.86, 0)
        let headTop = mtb ? P(0.42, 0.94, 0) : P(0.40, 0.88, 0)
        let headBottom = mtb ? P(0.46, 0.78, 0) : P(0.44, 0.72, 0)
        let bikeFront = mtb ? P(0.59, frontR, 0) : P(0.56, frontR, 0)
        let front = type == .cargo ? P(1.44, frontR, 0) : bikeFront
        rig.front = front
        rig.rear = rear
        rig.bb = bb
        rig.wheelRadius = frontR
        rig.tireWidth = tire
        rig.rimDepth = min(tire * 0.7, 0.024)

        // Hjul: hver sin rig om akslen.
        rig.rearWheel = pivot(at: rear) { _ = wheel(at: rear, radius: rearR, tire: tire, valve: false) }
        rig.frontWheel = pivot(at: front) { rig.frontTire = wheel(at: front, radius: frontR, tire: tire, valve: true) }
        let tireAngle: Float = .pi / 4
        spots[.tire] = PartSpot(marker: front + P(cos(tireAngle), sin(tireAngle), 0) * (frontR - tire / 2) + P(0, 0, tire / 2), center: front, radius: frontR + 0.05, facing: P(0.5, 0, 1))
        rig.bolts[.tire] = Bolt(point: front + P(0, 0, 0.062), axis: P(0, 0, 1))
        spots[.frame] = PartSpot(marker: lerp(headBottom, bb, 0.45), center: lerp(bb, (headTop + rear) / 2, 0.5), radius: 0.55, facing: P(0, 0, 1))

        // Stel
        let seatDir = simd_normalize(seat - bb)
        tube(headTop, headBottom, r * 1.35, paint, .frame)
        tube(headBottom, bb, type == .electric ? r * 1.4 : r, paint, .frame)
        tube(bb, seat, r, paint, .frame)
        if upright {
            // Lavt, buet overrør (lav indstigning).
            curve(lerp(headTop, headBottom, 0.35), P(0.05, 0.50, 0), lerp(bb, seat, 0.42), r)
        } else {
            tube(lerp(headTop, headBottom, 0.15), lerp(bb, seat, 0.95), r, paint, .frame)
        }
        for side: Float in [-1, 1] {
            let dropout = rear + P(0, 0, 0.055 * side)
            tube(bb + P(0, 0, 0.03 * side), dropout, r * 0.65, paint, .frame)
            tube(lerp(bb, seat, 0.93) + P(0, 0, 0.012 * side), dropout, r * 0.6, paint, .frame)
        }
        add(Self.cylinder(height: 0.08, radius: r * 1.3), paint, .frame, at: bb, rotation: alongZ)
        // Flaskeholderskruer på skrårøret.
        for t: Float in [0.4, 0.56] {
            boltHead(at: lerp(headBottom, bb, t) + P(0, 0, (type == .electric ? r * 1.4 : r) + 0.002), axis: P(0, 0, 1), part: .frame)
        }
        rig.bolts[.frame] = Bolt(point: lerp(headBottom, bb, 0.4) + P(0, 0, (type == .electric ? r * 1.4 : r) + 0.005), axis: P(0, 0, 1))

        // Forgaffel (cargo: ekstra styrerør helt fremme)
        let forkTop: P
        if type == .cargo {
            let ftTop = P(1.32, 0.72, 0), ftBottom = P(1.36, 0.58, 0)
            tube(ftTop, ftBottom, r * 1.35, paint, .frame)
            polyline([lerp(bb, headBottom, 0.08), P(0.20, 0.27, 0), P(1.12, 0.27, 0), P(1.14, 0.64, 0), lerp(ftTop, ftBottom, 0.4)], r * 1.2, paint, .frame)
            fork(top: ftBottom, axle: front, r: r, suspension: false)
            forkTop = ftBottom
            cargoBox()
        } else {
            fork(top: headBottom, axle: front, r: r, suspension: mtb)
            forkTop = headBottom
        }

        // Sadel + sadelpind (glider langs sadelrøret), sadelklemme med skrue.
        let saddlePoint = seat + seatDir * (mtb ? 0.16 : 0.12)
        let saddleSize: P = switch type {
        case .road: P(0.27, 0.04, 0.12)
        case .mountain: P(0.26, 0.045, 0.14)
        default: P(0.25, 0.065, 0.19)
        }
        rig.saddle = pivot(at: seat) {
            tube(seat - seatDir * 0.14, saddlePoint, r * 0.7, metal, .saddle)
            add(Self.box(saddleSize, cornerRadius: saddleSize.y * 0.45), leather, .saddle, at: saddlePoint + P(-0.01, 0.03, 0))
        }
        rig.seatDir = seatDir
        add(Self.cylinder(height: 0.028, radius: r * 1.35), darkMetal, .saddle, at: seat - seatDir * 0.012, rotation: simd_quatf(from: P(0, 1, 0), to: seatDir))
        boltHead(at: seat - seatDir * 0.012 + P(0, 0, r * 1.35), axis: P(0, 0, 1), part: .saddle)
        rig.bolts[.saddle] = Bolt(point: seat - seatDir * 0.012 + P(0, 0, r * 1.35 + 0.004), axis: P(0, 0, 1))
        spots[.saddle] = PartSpot(marker: saddlePoint + P(-0.01, saddleSize.y + 0.03, 0), center: saddlePoint, radius: 0.2, facing: P(-0.4, 0, 1))

        // Styr: drejer om styrerøret.
        let steer = simd_normalize(headTop - headBottom)
        rig.steer = steer
        rig.handlebar = pivot(at: headTop) { rig.barCenter = handlebar(headTop: headTop, headBottom: headBottom) }
        let barCenter = rig.barCenter
        spots[.handlebar] = PartSpot(marker: barCenter + P(0, 0.03, 0), center: barCenter, radius: mtb ? 0.38 : 0.32, facing: P(1, 0, 0.55))

        // Bagagebærer og skærme
        var rearLightPos = seat + P(-0.045, 0.02, 0)
        if upright {
            let rackY = rearR * 2 + 0.09
            let rackFront = rear.x + 0.17, rackBack = rear.x - 0.24
            add(Self.box(P(rackFront - rackBack, 0.012, 0.14)), darkMetal, nil, at: P((rackFront + rackBack) / 2, rackY, 0))
            for side: Float in [-1, 1] {
                tube(rear + P(0, 0, 0.065 * side), P(rackBack + 0.04, rackY, 0.065 * side), 0.006, darkMetal, nil)
                tube(P(rackFront, rackY, 0.05 * side), lerp(bb, seat, 0.9) + P(0, 0, 0.02 * side), 0.005, darkMetal, nil)
            }
            rearLightPos = P(rackBack - 0.015, rackY - 0.03, 0)
            fender(at: rear, radius: rearR + 0.03, from: 25, to: 195, width: tire * 1.6)
            fender(at: front, radius: frontR + 0.03, from: -15, to: 150, width: tire * 1.6)
        }

        // Lygter (på racer og MTB sidder forlygten på styret og drejer med det).
        let frontLightPos = switch type {
        case .cargo: P(1.40, 0.64, 0)
        case .road, .mountain: barCenter + P(0.05, -0.035, 0)
        default: forkTop + P(0.07, 0.0, 0)
        }
        within(type == .road || type == .mountain ? rig.handlebar : root) {
            add(Self.cylinder(height: 0.06, radius: 0.026), darkMetal, .lights, at: frontLightPos, rotation: alongX)
            rig.lenses.append(add(Self.cylinder(height: 0.008, radius: 0.022), frontLamp, .lights, at: frontLightPos + P(0.031, 0, 0), rotation: alongX))
        }
        rig.lenses.append(add(Self.box(P(0.025, 0.05, 0.045)), rearLamp, .lights, at: rearLightPos))
        rig.frontLight = frontLightPos
        rig.bolts[.lights] = Bolt(point: frontLightPos + P(-0.01, 0, 0.03), axis: P(0, 0, 1))
        spots[.lights] = PartSpot(marker: frontLightPos + P(0.035, 0, 0), center: frontLightPos, radius: 0.16, facing: P(1, 0, 0.6))

        // Elcykel: batteri på skrårøret
        if type == .electric {
            let dir = simd_normalize(bb - headBottom)
            let up = P(dir.y, -dir.x, 0) * (dir.x > 0 ? 1 : -1)
            let center = lerp(headBottom, bb, 0.45) + up * 0.05
            add(Self.box(P(0.36, 0.065, 0.08), cornerRadius: 0.018), leather, nil, at: center, rotation: simd_quatf(from: P(1, 0, 0), to: dir))
        }

        drivetrain(bb: bb, rear: rear)
        brakes(rear: rear, rearR: rearR, seatTop: lerp(bb, seat, 0.93), front: front, frontR: frontR, forkTop: forkTop, tire: tire)
        addColliders()
        return root
    }

    /// Returnerer dækket.
    private func wheel(at c: P, radius R: Float, tire t: Float, valve: Bool) -> ModelEntity {
        let tireEntity = add(Self.ring(outer: R, inner: R - t, depth: t * 0.95, chamfer: t * 0.42), rubber, .tire, at: c)
        let rimInner = R - t - 0.022
        add(Self.ring(outer: R - t + 0.002, inner: rimInner, depth: min(t * 0.7, 0.024), chamfer: 0.003), metal, nil, at: c)
        add(Self.cylinder(height: 0.11, radius: 0.016), metal, nil, at: c, rotation: alongZ)
        for side: Float in [-1, 1] {
            add(Self.cylinder(height: 0.008, radius: 0.011), darkMetal, nil, at: c + P(0, 0, 0.058 * side), rotation: alongZ)
        }
        let spoke = Self.cylinder(height: rimInner - 0.01, radius: 0.0016)
        for i in 0..<18 {
            let a = Float(i) / 18 * 2 * .pi
            let side: Float = i.isMultiple(of: 2) ? 1 : -1
            let hub = c + P(0, 0, 0.035 * side)
            let rim = c + P(cos(a), sin(a), 0) * (rimInner + 0.002)
            let dir = simd_normalize(rim - hub)
            let entity = ModelEntity(mesh: spoke, materials: [metal])
            entity.position = hub + dir * (rimInner - 0.01) / 2 + dir * 0.008
            entity.orientation = simd_quatf(from: P(0, 1, 0), to: dir)
            register(entity, metal, nil)
        }
        if valve {
            // Ventil nederst foran, peger ind mod navet.
            let a: Float = -55 * .pi / 180
            let dir = P(cos(a), sin(a), 0)
            tube(c + dir * (rimInner + 0.012), c + dir * (rimInner - 0.02), 0.0035, metal, .tire)
            add(Self.cylinder(height: 0.012, radius: 0.0048), darkMetal, .tire, at: c + dir * (rimInner - 0.025), rotation: simd_quatf(from: P(0, 1, 0), to: dir))
            rig.valve = c + dir * (rimInner - 0.031)
            rig.valveDir = -dir
        }
        return tireEntity
    }

    private func fork(top: P, axle: P, r: Float, suspension: Bool) {
        add(Self.box(P(0.05, 0.03, 0.15)), paint, .frame, at: top + P(0.005, -0.01, 0))
        for side: Float in [-1, 1] {
            let a = top + P(0, -0.02, 0.06 * side), b = axle + P(0, 0, 0.06 * side)
            if suspension {
                let mid = lerp(a, b, 0.45)
                tube(a, mid, 0.017, metal, .frame)
                tube(mid, b, 0.024, darkMetal, .frame)
            } else {
                tube(a, b, r * 0.75, paint, .frame)
            }
        }
    }

    /// Returnerer styrets midtpunkt.
    private func handlebar(headTop: P, headBottom: P) -> P {
        let steer = simd_normalize(headTop - headBottom)
        let stemBase = headTop + steer * 0.05
        let grip = pbr(UIColor(white: 0.14, alpha: 1), roughness: 0.75)
        let hasGears = bike.drivetrain != .singleSpeed
        let hasLevers = bike.brakes != .coaster
        let c: P
        switch bike.type {
        case .road:
            c = P(0.52, 0.93, 0)
            tube(headTop - steer * 0.02, stemBase, 0.017, darkMetal, .handlebar)
            tube(stemBase, c, 0.016, darkMetal, .handlebar)
            topCap(stemBase + steer * 0.004, steer)
            tube(c + P(0, 0, -0.21), c + P(0, 0, 0.21), 0.012, darkMetal, .handlebar)
            for side: Float in [1, -1] {
                let z = 0.21 * side
                polyline([c + P(0, 0, z), c + P(0.07, -0.01, z), c + P(0.10, -0.05, z), c + P(0.09, -0.11, z), c + P(0.03, -0.13, z), c + P(-0.01, -0.11, z)], 0.012, grip, .handlebar)
                if hasLevers { lever(at: c + P(0.07, -0.01, z), to: c + P(0.085, -0.08, z), grip: c + P(0.05, -0.11, z), side: side) }
            }
            // Racerstyr: man skifter ved at svinge bremsegrebet indad.
            if hasGears, let right = rig.levers.first {
                rig.shifter = BikeRig.Lever(entity: right.entity, pivot: right.pivot, tip: right.tip, axis: P(1, 0, 0))
            }
        case .mountain:
            c = P(0.52, 0.99, 0)
            tube(headTop - steer * 0.02, stemBase, 0.02, darkMetal, .handlebar)
            tube(stemBase, c, 0.018, darkMetal, .handlebar)
            topCap(stemBase + steer * 0.004, steer)
            tube(c + P(0, 0, -0.36), c + P(0, 0, 0.36), 0.013, darkMetal, .handlebar)
            for side: Float in [1, -1] {
                tube(c + P(0, 0, 0.26 * side), c + P(0, 0, 0.37 * side), 0.017, grip, .handlebar)
                if hasLevers { lever(at: c + P(0.01, 0, 0.22 * side), to: c + P(0.08, -0.01, 0.27 * side), grip: c + P(0, 0, 0.3 * side), side: side) }
            }
            if hasGears {
                // Tommelfingerpal under styret.
                let p = c + P(0.0, -0.024, 0.2)
                let paddle = pivot(at: p) {
                    add(Self.box(P(0.03, 0.016, 0.022)), darkMetal, .gears, at: p + P(0, 0.008, 0))
                    add(Self.box(P(0.045, 0.006, 0.014)), darkMetal, .gears, at: p + P(0.035, -0.004, -0.004))
                }
                rig.shifter = BikeRig.Lever(entity: paddle, pivot: p, tip: p + P(0.055, -0.004, -0.004), axis: P(0, 1, 0))
            }
        default:
            c = P(0.39, 1.06, 0)
            tube(headTop - steer * 0.02, c, 0.016, metal, .handlebar)
            topCap(c + steer * 0.014, steer)
            for side: Float in [1, -1] {
                let pts = [c, c + P(0, 0, 0.11 * side), c + P(-0.06, 0.02, 0.23 * side), c + P(-0.16, 0.025, 0.28 * side)]
                polyline(pts, 0.012, metal, .handlebar)
                let g0 = c + P(-0.14, 0.025, 0.275 * side), g1 = c + P(-0.25, 0.025, 0.29 * side)
                if side > 0, hasGears {
                    // Drejegreb til navgear inderst på højre håndtag.
                    let split = lerp(g0, g1, 0.38)
                    let axis = simd_normalize(g1 - g0)
                    let twist = pivot(at: g0) {
                        tube(g0, split, 0.02, darkMetal, .gears)
                        add(Self.box(P(0.012, 0.012, 0.03)), darkMetal, .gears, at: lerp(g0, split, 0.5) + P(0, 0.019, 0))
                    }
                    rig.shifter = BikeRig.Lever(entity: twist, pivot: g0, tip: lerp(g0, split, 0.5) + P(0, 0.025, 0), axis: axis)
                    tube(split, g1, 0.018, grip, .handlebar)
                } else {
                    tube(g0, g1, 0.018, grip, .handlebar)
                }
                if hasLevers { lever(at: c + P(-0.12, -0.012, 0.245 * side), to: c + P(-0.22, -0.024, 0.255 * side), grip: lerp(g0, g1, 0.6), side: side) }
            }
        }
        return c
    }

    private func topCap(_ p: P, _ axis: P) {
        boltHead(at: p, axis: axis, part: .handlebar, radius: 0.011)
        rig.bolts[.handlebar] = Bolt(point: p + axis * 0.004, axis: axis)
    }

    /// Bremsegreb som eget led, der drejer ind mod håndtaget (`grip`). Højre greb får en justerskrue.
    private func lever(at a: P, to b: P, grip: P, side: Float) {
        let axis = simd_normalize(simd_cross(b - a, grip - a))
        let entity = pivot(at: a) {
            add(Self.lowSphere(radius: 0.011), darkMetal, .brakes, at: a)
            tube(a, b, 0.0075, darkMetal, .brakes)
        }
        rig.levers.append(BikeRig.Lever(entity: entity, pivot: a, tip: b, axis: axis))
        guard side > 0 else { return }
        // Justerskruen sidder hvor kablet forlader grebet og peger skråt op mod rytteren.
        let dir = simd_normalize(P(-0.45, 0.8, -0.2))
        let base = a + P(0.01, 0.006, -0.004)
        let barrel = pivot(at: base) {
            add(Self.cylinder(height: 0.024, radius: 0.0085), metal, .brakes, at: base + dir * 0.012, rotation: simd_quatf(from: P(0, 1, 0), to: dir))
            add(Self.box(P(0.004, 0.024, 0.02)), darkMetal, .brakes, at: base + dir * 0.012, rotation: simd_quatf(from: P(0, 1, 0), to: dir))
        }
        rig.barrel = BikeRig.Lever(entity: barrel, pivot: base, tip: base + dir * 0.024, axis: dir)
    }

    private func cargoBox() {
        let x0: Float = 0.28, x1: Float = 1.10, y0: Float = 0.29, h: Float = 0.30, w: Float = 0.52, t: Float = 0.016
        let cx = (x0 + x1) / 2, cy = y0 + h / 2
        add(Self.box(P(x1 - x0, t, w)), wood, nil, at: P(cx, y0, 0))
        add(Self.box(P(t, h, w)), wood, nil, at: P(x0, cy, 0))
        add(Self.box(P(t, h, w)), wood, nil, at: P(x1, cy, 0))
        add(Self.box(P(x1 - x0, h, t)), wood, nil, at: P(cx, cy, w / 2))
        add(Self.box(P(x1 - x0, h, t)), wood, nil, at: P(cx, cy, -w / 2))
    }

    private func drivetrain(bb: P, rear: P) {
        let z: Float = 0.075
        let ringR: Float = bike.type == .road ? 0.105 : 0.095
        let cogR: Float = 0.04
        rig.chainZ = z

        // Kranken: klinge, edderkop, pedalarme og pedaler (der selv drejer om akslen).
        let a: Float = -0.9
        let arm = P(cos(a), sin(a), 0) * 0.17
        rig.crank = pivot(at: bb) {
            add(Self.ring(outer: ringR, inner: ringR - 0.03, depth: 0.006, chamfer: 0.002), metal, .chain, at: bb + P(0, 0, z))
            for i in 0..<5 {
                let angle = Float(i) / 5 * 2 * .pi + 0.3
                let dir = P(cos(angle), sin(angle), 0)
                add(Self.box(P(ringR - 0.02, 0.014, 0.006)), metal, .chain, at: bb + dir * (ringR - 0.02) / 2 + P(0, 0, z + 0.004), rotation: simd_quatf(angle: angle, axis: P(0, 0, 1)))
            }
            for (side, offset) in [(Float(1), arm), (Float(-1), -arm)] {
                let start = bb + P(0, 0, 0.088 * side)
                tube(start, start + offset, 0.011, darkMetal, .pedals)
                let spindle = start + offset
                rig.pedals.append(pivot(at: spindle) {
                    tube(spindle, spindle + P(0, 0, 0.03 * side), 0.005, metal, .pedals)
                    add(Self.box(P(0.09, 0.022, 0.075)), darkMetal, .pedals, at: spindle + P(0, 0, 0.05 * side))
                })
            }
            boltHead(at: bb + P(0, 0, 0.088 + 0.011), axis: P(0, 0, 1), part: .pedals, radius: 0.009)
        }
        rig.bolts[.pedals] = Bolt(point: bb + P(0, 0, 0.088 + 0.015), axis: P(0, 0, 1))
        rig.bolts[.chain] = rig.bolts[.pedals]

        within(rig.rearWheel) {
            switch bike.drivetrain {
            case .derailleur:
                rig.cassette = pivot(at: rear) {
                    for i in 0..<7 {
                        add(Self.cylinder(height: 0.003, radius: 0.032 + 0.0055 * Float(i)), metal, .gears, at: rear + P(0, 0, z - 0.0055 * Float(i)), rotation: alongZ)
                    }
                }
            case .hubGear, .singleSpeed:
                if bike.drivetrain == .hubGear {
                    add(Self.cylinder(height: 0.09, radius: 0.042), darkMetal, .gears, at: rear, rotation: alongZ)
                }
                rig.cassette = pivot(at: rear) {
                    add(Self.cylinder(height: 0.004, radius: cogR), metal, .gears, at: rear + P(0, 0, z), rotation: alongZ)
                    add(Self.box(P(cogR * 1.6, 0.006, 0.006)), darkMetal, .gears, at: rear + P(0, 0, z + 0.003))
                }
            }
        }
        if bike.drivetrain == .derailleur {
            let body = rear + P(-0.015, -0.08, z + 0.012)
            rig.derailleur = pivot(at: rear) {
                add(Self.box(P(0.035, 0.08, 0.014)), darkMetal, .gears, at: body)
                for dy: Float in [-0.03, 0.03] {
                    add(Self.cylinder(height: 0.008, radius: 0.012), darkMetal, .gears, at: body + P(0, dy, -0.012), rotation: alongZ)
                }
            }
            rig.bolts[.gears] = Bolt(point: body + P(0, 0.025, 0.01), axis: P(0, 0, 1))
        } else {
            rig.bolts[.gears] = Bolt(point: rear + P(0, 0, 0.066), axis: P(0, 0, 1))
        }

        // Kæde af led, der kan køre rundt (lyse og mørke led på skift, så bevægelsen kan ses).
        rig.chain = ChainLoop(ring: SIMD2(bb.x, bb.y), cog: SIMD2(rear.x, rear.y), ringR: ringR - 0.002, cogR: cogR)
        let count = Int((rig.chain.length / 0.024 / 2).rounded()) * 2
        let pitch = rig.chain.length / Float(count)
        let link = Self.box(P(pitch * 0.9, 0.009, 0.007))
        for i in 0..<count {
            let (p, angle) = rig.chain.point(at: Float(i) * pitch)
            rig.links.append(add(link, i.isMultiple(of: 2) ? darkMetal : metal, .chain, at: P(p.x, p.y, z), rotation: simd_quatf(angle: angle, axis: P(0, 0, 1))))
        }
        let chainTop = lerp(bb + P(0, ringR, z), rear + P(0, cogR, z), 0.5)
        spots[.chain] = PartSpot(marker: chainTop, center: lerp(bb, rear, 0.5) + P(0, 0, z), radius: simd_length(bb - rear) / 2 + 0.1, facing: P(-0.15, 0, 1))
        spots[.gears] = PartSpot(marker: rear + P(0, 0, z + 0.01), center: rear + P(0, -0.03, z), radius: 0.17, facing: P(-0.35, 0, 1))
        spots[.pedals] = PartSpot(marker: bb + arm + P(0, 0.02, 0.14), center: bb + P(0, 0, 0.05), radius: 0.24, facing: P(0.25, 0, 1))
    }

    private func brakes(rear: P, rearR: Float, seatTop: P, front: P, frontR: Float, forkTop: P, tire: Float) {
        let wheels = [(rear, rearR, seatTop, rig.rearWheel), (front, frontR, forkTop, rig.frontWheel)]
        let rimDepth = min(tire * 0.7, 0.024)
        // Hotspot og klodser på forbremsen (bagbremsen ved fodbremse).
        switch bike.brakes {
        case .rim:
            for (axle, R, toward, _) in wheels {
                let dir = simd_normalize(toward - axle)
                let pos = axle + dir * (R + 0.015)
                add(Self.box(P(0.03, 0.045, 0.12)), darkMetal, .brakes, at: pos)
                let tangent = P(-dir.y, dir.x, 0)
                var pads: [BikeRig.Pad] = []
                for side: Float in [-1, 1] {
                    let padPos = axle + dir * (R - tire - 0.012) + P(0, 0, side * (rimDepth / 2 + 0.011))
                    tube(pos + P(0, 0, side * 0.055), padPos + P(0, 0, side * 0.006), 0.004, darkMetal, .brakes)
                    let pad = add(Self.box(P(0.012, 0.042, 0.009)), rubber, .brakes, at: padPos, rotation: simd_quatf(from: P(0, 1, 0), to: tangent))
                    pads.append(BikeRig.Pad(entity: pad, squeeze: P(0, 0, -side * 0.0075), slide: simd_normalize(-tangent * 0.8 + P(0, 0, side * 0.6))))
                }
                rig.pads = pads
                rig.frontBrake = pos
                rig.bolts[.brakes] = Bolt(point: pos + P(0, 0, 0.064), axis: P(0, 0, 1))
                spots[.brakes] = PartSpot(marker: pos + P(0, 0, 0.065), center: pos + P(0, -0.04, 0), radius: 0.16, facing: P(0.7, 0, 1))
            }
        case .disc:
            for (axle, _, _, wheelRig) in wheels {
                within(wheelRig) {
                    add(Self.ring(outer: 0.08, inner: 0.05, depth: 0.003, chamfer: 0.001), metal, .brakes, at: axle + P(0, 0, -0.068))
                }
                let caliper = axle + P(-0.05, 0.06, -0.072)
                add(Self.box(P(0.05, 0.03, 0.025)), darkMetal, .brakes, at: caliper)
                let out = simd_normalize(P(-0.05, 0.06, 0))
                rig.pads = [Float(-1), 1].map { side in
                    let pad = add(Self.box(P(0.032, 0.02, 0.004)), rubber, .brakes, at: axle + P(-0.05, 0.06, -0.068) - out * 0.006 + P(0, 0, side * 0.0055))
                    return BikeRig.Pad(entity: pad, squeeze: P(0, 0, -side * 0.0025), slide: out)
                }
                rig.frontBrake = caliper
                rig.bolts[.brakes] = Bolt(point: caliper + P(0, 0, -0.017), axis: P(0, 0, -1))
                spots[.brakes] = PartSpot(marker: axle + P(-0.05, 0.06, -0.09), center: axle + P(0, 0, -0.07), radius: 0.15, facing: P(0.3, 0, -1))
            }
            rig.brakeOnLeft = true
        case .roller:
            for (axle, _, _, _) in wheels {
                let drum = add(Self.cylinder(height: 0.03, radius: 0.05), darkMetal, .brakes, at: axle + P(0, 0, -0.06), rotation: alongZ)
                rig.pads = [BikeRig.Pad(entity: drum, squeeze: .zero, slide: P(0, 0, -1))]
                rig.frontBrake = axle + P(0, 0, -0.06)
                rig.bolts[.brakes] = Bolt(point: axle + P(0, 0, -0.08), axis: P(0, 0, -1))
                spots[.brakes] = PartSpot(marker: axle + P(0, 0, -0.08), center: axle + P(0, 0, -0.06), radius: 0.14, facing: P(0.3, 0, -1))
            }
            rig.brakeOnLeft = true
        case .coaster:
            let drum = add(Self.cylinder(height: 0.03, radius: 0.045), darkMetal, .brakes, at: rear + P(0, 0, -0.06), rotation: alongZ)
            tube(rear + P(0, 0, -0.07), rear + P(0.15, -0.01, -0.07), 0.008, darkMetal, .brakes)
            rig.pads = [BikeRig.Pad(entity: drum, squeeze: .zero, slide: P(0, 0, -1))]
            rig.frontBrake = rear + P(0, 0, -0.06)
            rig.bolts[.brakes] = Bolt(point: rear + P(0.14, -0.01, -0.08), axis: P(0, 0, -1))
            rig.brakeOnLeft = true
            spots[.brakes] = PartSpot(marker: rear + P(0, 0, -0.08), center: rear + P(0.05, 0, -0.06), radius: 0.16, facing: P(-0.3, 0, -1))
        }
    }

    // MARK: - Primitiver

    private let alongZ = simd_quatf(angle: .pi / 2, axis: P(1, 0, 0))
    private let alongX = simd_quatf(angle: .pi / 2, axis: P(0, 0, 1))

    private func register(_ entity: ModelEntity, _ material: any RealityKit.Material, _ part: BikePart?) {
        pieces.append(Bike3DPiece(entity: entity, part: part, material: material))
        guard let part else { return parent.addChild(entity) }
        group(for: part).addChild(entity)
    }

    /// Én CollisionComponent pr. delgruppe (ikke pr. mesh), så fysikmotoren kun har få aktører at flytte.
    /// Formen er én kasse pr. mesh i gruppens koordinater: en samlet kasse om fx lygter eller bremser
    /// (foran og bagpå) ville dække halvdelen af cyklen og stjæle tryk fra andre dele.
    private func addColliders() {
        var stack = [root]
        while let e = stack.popLast() {
            stack += e.children
            guard e.components.has(InputTargetComponent.self) else { continue }
            let shapes = e.children.compactMap { child -> ShapeResource? in
                guard let bounds = (child as? ModelEntity)?.model?.mesh.bounds else { return nil }
                // Rummelig trykflade: tynde dele (kæde, kabler, håndtag) får mindst 5 cm i hver retning.
                let size = simd_max(bounds.extents, P(repeating: 0.05))
                return ShapeResource.generateBox(size: size)
                    .offsetBy(rotation: child.orientation, translation: child.position + child.orientation.act(bounds.center))
            }
            // Tom maske: kun til tryk (raycast), ingen kontakter mellem cyklens egne, overlappende dele.
            e.components.set(CollisionComponent(shapes: shapes, filter: CollisionFilter(group: .default, mask: [])))
        }
    }

    /// Delens gruppe i den aktuelle forælder (navngivet med `BikePart.rawValue`, så tryk kan føres tilbage til delen).
    private func group(for part: BikePart) -> Entity {
        if let group = parent.children.first(where: { $0.name == part.rawValue }) { return group }
        let group = Entity()
        group.name = part.rawValue
        group.components.set(InputTargetComponent())
        parent.addChild(group)
        return group
    }

    /// Ny bevægelig gruppe med drejepunkt i `point`. Indholdet bygges i cyklens koordinater.
    private func pivot(at point: P, _ build: () -> Void) -> Entity {
        let rig = Entity()
        rig.position = point
        let inner = Entity()
        inner.position = -point
        rig.addChild(inner)
        parent.addChild(rig)
        within(rig, build)
        return rig
    }

    /// Byg videre inde i en eksisterende rig (eller roden).
    private func within(_ entity: Entity, _ build: () -> Void) {
        let saved = parent
        parent = entity === root ? root : entity.children[0]
        build()
        parent = saved
    }

    /// Lille skruehoved, der vender langs `axis`.
    private func boltHead(at p: P, axis: P, part: BikePart, radius: Float = 0.0065) {
        add(Self.cylinder(height: 0.005, radius: radius), darkMetal, part, at: p, rotation: simd_quatf(from: P(0, 1, 0), to: axis))
    }

    @discardableResult
    private func add(_ mesh: MeshResource, _ material: any RealityKit.Material, _ part: BikePart?, at position: P, rotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)) -> ModelEntity {
        let entity = ModelEntity(mesh: mesh, materials: [material])
        // Ekstruderede meshes ligger ikke centreret i z; ret det her.
        entity.position = position - rotation.act(P(0, 0, mesh.bounds.center.z))
        entity.orientation = rotation
        register(entity, material, part)
        return entity
    }

    private func tube(_ a: P, _ b: P, _ radius: Float, _ material: any RealityKit.Material, _ part: BikePart?) {
        let d = b - a
        let length = simd_length(d)
        guard length > 0.0001 else { return }
        add(Self.cylinder(height: length, radius: radius), material, part, at: (a + b) / 2, rotation: simd_quatf(from: P(0, 1, 0), to: d / length))
    }

    /// Rør gennem flere punkter med kugler i leddene, så knæk ser bløde ud.
    private func polyline(_ points: [P], _ radius: Float, _ material: any RealityKit.Material, _ part: BikePart?) {
        for (a, b) in zip(points, points.dropFirst()) { tube(a, b, radius, material, part) }
        for p in points.dropFirst().dropLast() { add(Self.lowSphere(radius: radius), material, part, at: p) }
    }

    /// Kvadratisk Bézier-rør (det buede overrør på bycykler).
    private func curve(_ a: P, _ control: P, _ b: P, _ radius: Float) {
        let points = (0...8).map { i -> P in
            let t = Float(i) / 8
            return (1 - t) * (1 - t) * a + 2 * (1 - t) * t * control + t * t * b
        }
        polyline(points, radius, paint, .frame)
    }

    private func fender(at c: P, radius: Float, from a0: Double, to a1: Double, width: Float) {
        add(Self.ring(outer: radius, inner: radius - 0.01, depth: width, chamfer: 0.003, from: a0, to: a1), paint, nil, at: c)
    }

    /// Meshes genbruges på tværs af dele og bygninger (eger, skruer, kædeled, ringe). Delt cache.
    private static var meshCache: [String: MeshResource] = [:]

    private static func cached(_ key: String, _ make: () -> MeshResource) -> MeshResource {
        if let mesh = meshCache[key] { return mesh }
        let mesh = make()
        meshCache[key] = mesh
        return mesh
    }

    /// Kasse. Afrundede kasser koster ~13k trekanter uanset størrelse; brug kun `cornerRadius` på store, synlige dele.
    static func box(_ size: SIMD3<Float>, cornerRadius: Float = 0) -> MeshResource {
        cached("box|\(size)|\(cornerRadius)") {
            cornerRadius > 0 ? .generateBox(size: size, cornerRadius: cornerRadius) : .generateBox(size: size)
        }
    }

    static func cylinder(height: Float, radius: Float) -> MeshResource {
        cached("cyl|\(height)|\(radius)") { .generateCylinder(height: height, radius: radius) }
    }

    /// UV-kugle med 10×6 segmenter (100 trekanter mod ~8k for `generateSphere`).
    static func lowSphere(radius: Float) -> MeshResource {
        cached("sphere|\(radius)") {
            let seg = 10, rings = 6
            var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], indices: [UInt32] = []
            for j in 0...rings {
                let v = Float(j) / Float(rings) * .pi
                for i in 0...seg {
                    let u = Float(i) / Float(seg) * 2 * .pi
                    let n = SIMD3<Float>(sin(v) * cos(u), cos(v), sin(v) * sin(u))
                    normals.append(n)
                    positions.append(n * radius)
                }
            }
            for j in 0..<rings {
                for i in 0..<seg {
                    let a = UInt32(j * (seg + 1) + i), b = a + UInt32(seg + 1)
                    // Spring de udartede trekanter ved polerne over.
                    if j > 0 { indices += [a, a + 1, b] }
                    if j < rings - 1 { indices += [a + 1, b + 1, b] }
                }
            }
            var descriptor = MeshDescriptor(name: "lowSphere")
            descriptor.positions = MeshBuffers.Positions(positions)
            descriptor.normals = MeshBuffers.Normals(normals)
            descriptor.primitives = .triangles(indices)
            // try!: deskriptoren er bygget her og altid gyldig.
            return try! MeshResource.generate(from: [descriptor])
        }
    }

    /// Ring (eller bue) i xy-planet, ekstruderet langs z og centreret i z.
    static func ring(outer: Float, inner: Float, depth: Float, chamfer: Float, from a0: Double = 0, to a1: Double = 360) -> MeshResource {
        cached("ring|\(outer)|\(inner)|\(depth)|\(chamfer)|\(a0)|\(a1)") {
            var path = Path()
            if a1 - a0 >= 360 {
                path.addArc(center: .zero, radius: CGFloat(outer), startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                path.closeSubpath()
                path.addArc(center: .zero, radius: CGFloat(inner), startAngle: .degrees(360), endAngle: .zero, clockwise: true)
                path.closeSubpath()
            } else {
                path.addArc(center: .zero, radius: CGFloat(outer), startAngle: .degrees(a0), endAngle: .degrees(a1), clockwise: false)
                path.addArc(center: .zero, radius: CGFloat(inner), startAngle: .degrees(a1), endAngle: .degrees(a0), clockwise: true)
                path.closeSubpath()
            }
            var options = MeshResource.ShapeExtrusionOptions()
            options.extrusionMethod = .linear(depth: depth)
            options.chamferRadius = chamfer
            options.boundaryResolution = .uniformSegmentsPerSpan(segmentCount: 12)
            options.chamferResolution = .uniformSegmentsPerSpan(segmentCount: 3)
            // try!: input er faste, gyldige konstanter, så det kan kun fejle ved en programmeringsfejl.
            return try! MeshResource(extruding: path, extrusionOptions: options)
        }
    }

    /// Grå "ler"-look til de dele, der ikke er fremhævet. Mørkere grafit i mørk tilstand.
    static func faded(dark: Bool) -> PhysicallyBasedMaterial {
        pbr(UIColor(white: dark ? 0.30 : 0.70, alpha: 1), roughness: 0.6)
    }

    /// Fremhævningsfarve; `glow` 0...1 styrer pulsen.
    static func highlight(_ color: UIColor, glow: Float) -> PhysicallyBasedMaterial {
        emissive(color, intensity: 0.15 + 0.6 * glow)
    }

    /// Gennemsigtig trådmodel til scanningen.
    static func wire(_ color: UIColor, opacity: Float) -> UnlitMaterial {
        var m = UnlitMaterial(color: color)
        m.triangleFillMode = .lines
        m.blending = .transparent(opacity: .init(floatLiteral: opacity))
        return m
    }
}

// MARK: - Materialer og farver

func pbr(_ color: UIColor, roughness: Float, metallic: Float = 0, clearcoat: Float = 0) -> PhysicallyBasedMaterial {
    var m = PhysicallyBasedMaterial()
    m.baseColor = .init(tint: color)
    m.roughness = .init(floatLiteral: roughness)
    m.metallic = .init(floatLiteral: metallic)
    m.clearcoat = .init(floatLiteral: clearcoat)
    m.clearcoatRoughness = .init(floatLiteral: 0.1)
    return m
}

func emissive(_ color: UIColor, intensity: Float = 1.5) -> PhysicallyBasedMaterial {
    var m = pbr(color, roughness: 0.3)
    m.emissiveColor = .init(color: color)
    m.emissiveIntensity = intensity
    return m
}

private func lerp(_ a: P, _ b: P, _ t: Float) -> P { a + (b - a) * t }

/// "#1C6E8C" → UIColor. Ugyldig hex giver grå.
private func uiColor(hex: String) -> UIColor {
    guard let v = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")), radix: 16) else { return .systemGray }
    return UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}
