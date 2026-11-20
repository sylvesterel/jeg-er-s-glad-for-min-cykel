import Foundation
import Observation

/// Værkstedet for én cykel: hvilken del der er valgt, reparationer pr. del og besparelsen.
/// Bygges på ny når den aktive cykel skifter.
@Observable
final class GarageViewModel {
    let bike: Bike
    let repairs: [Repair]
    var selectedPart: BikePart?

    init(bike: Bike, selectedPart: BikePart? = nil) {
        self.bike = bike
        self.repairs = Catalog.repairs(for: bike)
        self.selectedPart = selectedPart
    }

    /// Samlet besparelse på alle reparationer man selv kan lave.
    var potentialSavings: Int {
        repairs.filter(\.difficulty.isDIY).reduce(0) { $0 + $1.savings }
    }

    /// Dele med mindst én reparation til denne cykel, i fast rækkefølge.
    var parts: [BikePart] {
        BikePart.allCases.filter { part in repairs.contains { $0.part == part } }
    }

    func repairs(for part: BikePart) -> [Repair] {
        repairs.filter { $0.part == part }.sorted { $0.difficulty < $1.difficulty }
    }

    /// Tryk på samme del igen fravælger den.
    func toggle(_ part: BikePart) {
        selectedPart = selectedPart == part ? nil : part
    }
}
