import Foundation

enum Difficulty: Int, CaseIterable, Comparable, Codable {
    case easy = 1, medium, hard, mechanic

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .easy: "Let"
        case .medium: "Middel"
        case .hard: "Svær"
        case .mechanic: "Kræver mekaniker"
        }
    }

    /// Kan brugeren selv udføre reparationen, eller skal vi henvise til en mekaniker?
    var isDIY: Bool { self != .mechanic }
}

struct GuideStep: Identifiable, Hashable, Codable {
    var id: String { title }
    let title: String
    let detail: String
    /// SF Symbol der illustrerer trinnet.
    let symbol: String
    var tip: String? = nil
    var warning: String? = nil
    /// 3D-animation der viser trinnet på cyklen. nil = kameraet kredser roligt om delen.
    var animation: StepAnimation? = nil
    /// Delen trinnet handler om, hvis den er en anden end reparationens (fx i en vedligeholdelsesguide).
    var part: BikePart? = nil
}

/// En kort 3D-animation på cykelmodellen, der viser hvad man gør i et guide-trin. Afspilles i loop.
enum StepAnimation: String, Codable, CaseIterable {
    case flipBike          // Vend cyklen, så den står på sadel og styr
    case removeFrontWheel  // Løsn og tag forhjulet af
    case removeRearWheel   // Løsn og tag baghjulet af
    case spinWheel         // Drej hjulet langsomt rundt (find hul, tjek om det slingrer)
    case deflateTire       // Luk luften ud af ventilen
    case pumpTire          // Pumpe på ventilen, dækket fyldes
    case leverTire         // Dækjern lirker dækket af fælgen
    case turnPedals        // Pedalerne drejes baglæns, kæden kører rundt
    case oilChain          // Olie dryppes på kæden mens den kører
    case wipeChain         // En klud tørrer kæden af
    case removeChain       // Kæden løftes af tandhjulene
    case squeezeBrake      // Bremsegrebet trykkes, klodserne tager fat
    case replaceBrakePads  // Gamle klodser ud, nye ind
    case adjustCable       // Justerskruen ved grebet drejes
    case shiftGears        // Gearskifteren klikkes, gearet skifter
    case moveSaddle        // Sadlen glider op og ned
    case tightenBolt       // Unbrakonøgle strammer en skrue på delen
    case loosenBolt        // Unbrakonøgle løsner en skrue på delen
    case alignHandlebar    // Styret drejes lige
    case switchLight       // Lygten tændes
    case unscrewPedal      // Pedalen skrues af
    case inspect           // Kameraet kredser roligt om delen
}

struct Repair: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let summary: String
    let part: BikePart
    let difficulty: Difficulty
    let minutes: Int
    let tools: [String]
    /// Pris for reservedele i DKK, hvis man selv gør det.
    let partsCost: Int
    /// Typisk pris hos en dansk cykelmekaniker i DKK (inkl. dele).
    let mechanicPrice: Int
    let steps: [GuideStep]
    /// nil = gælder alle cykler.
    var drivetrains: Set<Drivetrain>? = nil
    /// nil = gælder alle cykler.
    var brakeTypes: Set<BrakeType>? = nil

    var savings: Int { max(mechanicPrice - partsCost, 0) }

    func applies(to bike: Bike) -> Bool {
        (drivetrains?.contains(bike.drivetrain) ?? true)
            && (brakeTypes?.contains(bike.brakes) ?? true)
    }
}

extension FormatStyle where Self == IntegerFormatStyle<Int>.Currency {
    /// Hele kroner, dansk formatering: "1.250 kr."
    static var dkk: Self {
        .currency(code: "DKK").locale(Locale(identifier: "da_DK")).precision(.fractionLength(0))
    }
}
