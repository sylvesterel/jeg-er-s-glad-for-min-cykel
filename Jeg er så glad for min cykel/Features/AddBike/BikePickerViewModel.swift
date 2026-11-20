import Foundation
import Observation

@Observable
final class BikePickerViewModel {
    var searchText = ""
    /// nil = alle typer.
    var type: BikeType?

    /// Cykler der matcher søgning og filter, grupperet og sorteret efter mærke.
    var sections: [(brand: String, bikes: [Bike])] {
        let matches = Catalog.bikes.filter { bike in
            (type == nil || bike.type == type)
                && (searchText.isEmpty || bike.name.localizedStandardContains(searchText))
        }
        return Dictionary(grouping: matches, by: \.brand)
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { (brand: $0.key, bikes: $0.value.sorted { $0.model < $1.model }) }
    }

    func specs(for bike: Bike) -> String {
        let gears = bike.gears == 1 ? bike.drivetrain.title : "\(bike.gears) gear"
        return "\(bike.year) · \(gears) · \(bike.brakes.title)"
    }
}
