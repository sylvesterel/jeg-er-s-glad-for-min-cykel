import Foundation
import Observation

/// Udstyr og cykelvaner → en personlig vedligeholdelsesplan for den aktive cykel.
@Observable
final class MaintenanceViewModel {
    let bike: Bike
    private let defaults: UserDefaults

    var owned: Set<Equipment> {
        didSet { defaults.set(owned.map(\.rawValue).sorted().joined(separator: ","), forKey: Self.ownedKey) }
    }
    var frequency: RideFrequency {
        didSet { defaults.set(frequency.rawValue, forKey: Self.frequencyKey) }
    }

    private static let ownedKey = "maintenanceEquipment"
    private static let frequencyKey = "maintenanceFrequency"

    init(bike: Bike, defaults: UserDefaults = .standard) {
        self.bike = bike
        self.defaults = defaults
        let saved = defaults.string(forKey: Self.ownedKey)?.split(separator: ",") ?? []
        owned = Set(saved.compactMap { Equipment(rawValue: String($0)) })
        frequency = defaults.string(forKey: Self.frequencyKey).flatMap(RideFrequency.init) ?? .weekly
    }

    func toggle(_ equipment: Equipment) {
        if owned.contains(equipment) { owned.remove(equipment) } else { owned.insert(equipment) }
    }

    // MARK: - Plan

    var tasks: [MaintenanceTask] { MaintenanceCatalog.tasks.filter { $0.applies(to: bike) } }

    func interval(for task: MaintenanceTask) -> MaintenanceInterval { task.interval.adjusted(for: frequency) }

    /// Udstyr man mangler til opgaven, i fast rækkefølge.
    func missing(for task: MaintenanceTask) -> [Equipment] {
        Equipment.allCases.filter { task.equipment.contains($0) && !owned.contains($0) }
    }

    func isReady(_ task: MaintenanceTask) -> Bool { missing(for: task).isEmpty }

    /// Opgaver man kan gøre nu, grupperet efter hvor ofte.
    var groups: [(interval: MaintenanceInterval, tasks: [MaintenanceTask])] {
        MaintenanceInterval.allCases.compactMap { interval in
            let tasks = tasks.filter { isReady($0) && self.interval(for: $0) == interval }
            return tasks.isEmpty ? nil : (interval, tasks)
        }
    }

    /// Opgaver man først kan gøre, når man har købt noget.
    var blocked: [MaintenanceTask] { tasks.filter { !isReady($0) } }

    /// Dem, guiden kører: alt man kan gøre nu, undtagen det halvårlige. I katalogets rækkefølge.
    var guideTasks: [MaintenanceTask] {
        tasks.filter { isReady($0) && interval(for: $0) < .halfYear }
    }

    var guideMinutes: Int { guideTasks.reduce(0) { $0 + $1.minutes } }

    /// Opgaverne samlet til én guide, så den kan vises med `GuideView`.
    var guideRepair: Repair? {
        let tasks = guideTasks
        guard let first = tasks.first else { return nil }
        return Repair(
            id: "vedligeholdelse",
            title: "Vedligeholdelse",
            summary: tasks.map(\.title).joined(separator: ", "),
            part: first.part,
            difficulty: .easy,
            minutes: guideMinutes,
            tools: Equipment.allCases.filter { e in tasks.contains { $0.equipment.contains(e) } }.map(\.title),
            partsCost: tasks.reduce(0) { $0 + $1.consumablesCost },
            // ponytail: grov værdi, ca. 100 kr. pr. opgave hos en cykelsmed, højst et helt eftersyn.
            mechanicPrice: min(MaintenanceCatalog.servicePrice, tasks.count * 100),
            steps: tasks.flatMap(\.steps)
        )
    }
}
