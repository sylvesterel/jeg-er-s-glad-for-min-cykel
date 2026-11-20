import Foundation

enum BikeType: String, CaseIterable, Identifiable, Codable {
    case city, road, mountain, cargo, electric

    var id: Self { self }

    var title: String {
        switch self {
        case .city: "Bycykel"
        case .road: "Racercykel"
        case .mountain: "Mountainbike"
        case .cargo: "Ladcykel"
        case .electric: "Elcykel"
        }
    }

    var symbol: String {
        switch self {
        case .city: "bicycle"
        case .road: "figure.outdoor.cycle"
        case .mountain: "mountain.2"
        case .cargo: "shippingbox"
        case .electric: "bolt"
        }
    }
}

enum Drivetrain: String, Codable {
    case singleSpeed, hubGear, derailleur

    var title: String {
        switch self {
        case .singleSpeed: "Ingen gear"
        case .hubGear: "Navgear"
        case .derailleur: "Kædegear"
        }
    }
}

enum BrakeType: String, Codable {
    case coaster, rim, roller, disc

    var title: String {
        switch self {
        case .coaster: "Fodbremse"
        case .rim: "Fælgbremser"
        case .roller: "Rullebremser"
        case .disc: "Skivebremser"
        }
    }
}

struct Bike: Identifiable, Hashable, Codable {
    let id: String
    let brand: String
    let model: String
    let type: BikeType
    let year: Int
    let gears: Int
    let drivetrain: Drivetrain
    let brakes: BrakeType
    /// Stelfarve som hex (fx "#1C6E8C"). Bruges af 3D-visningen.
    let colorHex: String

    var name: String { "\(brand) \(model)" }
}

/// Dele på cyklen. Delt mellem reparationer og 3D-visningen (fremhævning).
enum BikePart: String, CaseIterable, Identifiable, Codable {
    case tire, chain, brakes, gears, lights, saddle, handlebar, pedals, frame

    var id: Self { self }

    var title: String {
        switch self {
        case .tire: "Dæk og slange"
        case .chain: "Kæde"
        case .brakes: "Bremser"
        case .gears: "Gear"
        case .lights: "Lygter"
        case .saddle: "Sadel"
        case .handlebar: "Styr"
        case .pedals: "Pedaler"
        case .frame: "Stel"
        }
    }

    var symbol: String {
        switch self {
        case .tire: "circle.circle"
        case .chain: "link"
        case .brakes: "hand.raised"
        case .gears: "gearshape.2"
        case .lights: "flashlight.on.fill"
        case .saddle: "chair"
        case .handlebar: "arrow.left.and.right"
        case .pedals: "shoeprints.fill"
        case .frame: "triangle"
        }
    }
}
