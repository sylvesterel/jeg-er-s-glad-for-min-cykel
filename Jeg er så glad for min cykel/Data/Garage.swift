import Foundation
import Observation

/// App-dækkende tilstand: brugerens cykler og den aktive cykel. Injiceres via `.environment(garage)`.
@Observable
final class Garage {
    private static let bikesKey = "bikeIDs"
    private static let selectedKey = "selectedBikeID"

    private(set) var bikes: [Bike]

    /// Den aktive cykel. At sætte en ny cykel tilføjer den også til `bikes`.
    var bike: Bike? {
        didSet {
            if let bike, !bikes.contains(bike) { bikes.append(bike) }
            save()
        }
    }

    init() {
        let defaults = UserDefaults.standard
        let ids = defaults.stringArray(forKey: Self.bikesKey) ?? []
        bikes = ids.compactMap { id in Catalog.bikes.first { $0.id == id } }
        let selected = defaults.string(forKey: Self.selectedKey)
        bike = bikes.first { $0.id == selected } ?? bikes.first
    }

    private func save() {
        UserDefaults.standard.set(bikes.map(\.id), forKey: Self.bikesKey)
        UserDefaults.standard.set(bike?.id, forKey: Self.selectedKey)
    }
}
