import Foundation

/// Brugerens profil. Mock-data; tallene udledes af reparationshistorikken.
struct Profile {
    struct Entry: Identifiable {
        let id = UUID()
        let date: Date
        let repair: Repair
    }

    struct Milestone: Identifiable {
        var id: String { title }
        let title: String
        let symbol: String
        let isUnlocked: Bool
    }

    let name: String
    let city: String
    let memberSince: Int
    let kmThisYear: Int
    /// Nyeste først.
    let history: [Entry]

    static let mock = Profile(
        name: "Mads P.",
        city: "København",
        memberSince: 2024,
        kmThisYear: 2_140,
        history: [
            ("2026-11-02", "skift-pedaler"),
            ("2026-09-27", "juster-rullebremse"),
            ("2026-08-04", "navgear-service"),
            ("2026-06-21", "rens-smoer-kaede"),
            ("2026-05-09", "skift-kaede"),
            ("2026-03-30", "juster-navgear"),
            ("2026-02-22", "lap-slange"),
            ("2026-01-14", "skift-daek"),
            ("2025-09-08", "skift-lygte-batteri"),
            ("2025-05-17", "rens-smoer-kaede"),
            ("2025-02-03", "juster-sadelhoejde"),
            ("2024-10-12", "lap-slange"),
        ].compactMap { day, id in
            guard let repair = Catalog.repairs.first(where: { $0.id == id }),
                  let date = try? Date(day, strategy: .iso8601.year().month().day())
            else { return nil }
            return Entry(date: date, repair: repair)
        }
    )
}

extension Profile {
    var initials: String {
        name.split(separator: " ").compactMap(\.first).map(String.init).joined()
    }

    var totalSaved: Int { history.map(\.repair.savings).reduce(0, +) }

    var hoursWrenched: Double { Double(history.map(\.repair.minutes).reduce(0, +)) / 60 }

    /// ponytail: fast faktor ~0,15 kg CO₂/km for en gennemsnitlig benzinbil.
    var co2SavedKg: Int { Int(Double(kmThisYear) * 0.15) }

    var year: Int { Calendar.current.component(.year, from: .now) }

    /// Akkumuleret besparelse i år, ét punkt pr. reparation (plus start 1. januar).
    var savingsThisYear: [(date: Date, total: Int)] {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        var total = 0
        let points = history.reversed()
            .filter { $0.date >= start }
            .map { entry -> (date: Date, total: Int) in
                total += entry.repair.savings
                return (entry.date, total)
            }
        return [(start, 0)] + points + [(.now, total)]
    }

    var milestones: [Milestone] {
        let ids = Set(history.map(\.repair.id))
        return [
            Milestone(title: "Første lappede slange", symbol: "bandage", isUnlocked: ids.contains("lap-slange")),
            Milestone(title: "10 reparationer", symbol: "wrench.and.screwdriver", isUnlocked: history.count >= 10),
            Milestone(title: "1.000 kr. sparet", symbol: "banknote", isUnlocked: totalSaved >= 1_000),
            Milestone(title: "Ny kæde", symbol: "link", isUnlocked: ids.contains("skift-kaede")),
            Milestone(title: "25 reparationer", symbol: "rosette", isUnlocked: history.count >= 25),
            Milestone(title: "5.000 kr. sparet", symbol: "banknote", isUnlocked: totalSaved >= 5_000),
        ]
    }
}
