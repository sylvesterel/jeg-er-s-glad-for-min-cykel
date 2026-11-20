import Foundation

/// Mock-katalog over cykler og reparationer.
/// ponytail: lokale data i appen. Skift `bikes` ud med et API-kald (fx Bike Index / 99 Spokes) når der skal rigtige data på.
enum Catalog {
    static let bikes: [Bike] = [
        Bike(id: "kildemoes-city-3", brand: "Kildemoes", model: "City 3", type: .city, year: 2023, gears: 3, drivetrain: .hubGear, brakes: .roller, colorHex: "#1F3A5F"),
        Bike(id: "avenue-broadway", brand: "Avenue", model: "Broadway", type: .city, year: 2022, gears: 7, drivetrain: .hubGear, brakes: .roller, colorHex: "#2E2E2E"),
        Bike(id: "winther-wave", brand: "Winther", model: "Wave", type: .city, year: 2021, gears: 1, drivetrain: .singleSpeed, brakes: .coaster, colorHex: "#C8D5B9"),
        Bike(id: "raleigh-darwin", brand: "Raleigh", model: "Darwin", type: .city, year: 2023, gears: 7, drivetrain: .hubGear, brakes: .rim, colorHex: "#8C1C13"),
        Bike(id: "batavus-finez", brand: "Batavus", model: "Finez", type: .city, year: 2024, gears: 8, drivetrain: .hubGear, brakes: .roller, colorHex: "#4A6FA5"),
        Bike(id: "gazelle-ultimate-c8", brand: "Gazelle", model: "Ultimate C8", type: .electric, year: 2024, gears: 8, drivetrain: .hubGear, brakes: .disc, colorHex: "#3B3B3B"),
        Bike(id: "trek-fx3", brand: "Trek", model: "FX 3", type: .city, year: 2023, gears: 20, drivetrain: .derailleur, brakes: .disc, colorHex: "#0B5394"),
        Bike(id: "specialized-allez", brand: "Specialized", model: "Allez", type: .road, year: 2022, gears: 16, drivetrain: .derailleur, brakes: .rim, colorHex: "#D62828"),
        Bike(id: "canyon-endurace", brand: "Canyon", model: "Endurace 7", type: .road, year: 2024, gears: 22, drivetrain: .derailleur, brakes: .disc, colorHex: "#6C757D"),
        Bike(id: "cube-aim", brand: "Cube", model: "Aim Race", type: .mountain, year: 2023, gears: 18, drivetrain: .derailleur, brakes: .disc, colorHex: "#F4A261"),
        Bike(id: "bullitt-classic", brand: "Larry vs Harry", model: "Bullitt", type: .cargo, year: 2022, gears: 8, drivetrain: .hubGear, brakes: .disc, colorHex: "#2A9D8F"),
        Bike(id: "christiania-light", brand: "Christiania", model: "Light", type: .cargo, year: 2021, gears: 7, drivetrain: .hubGear, brakes: .roller, colorHex: "#264653"),
    ]

    static func repairs(for bike: Bike) -> [Repair] {
        repairs.filter { $0.applies(to: bike) }
    }
}
