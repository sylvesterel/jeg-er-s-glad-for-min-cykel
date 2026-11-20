import Foundation
import Observation

/// Logik bag "Tilføj cykel": falsk 3D-scanning og opslag på stelnummer.
@Observable
final class AddBikeViewModel {

    // MARK: Scanning

    private(set) var scanBike = Catalog.bikes[0]
    /// 0...1
    private(set) var scanProgress = 0.0
    private(set) var scanFound = false
    /// Øges for at starte en ny scanning (bruges som `.task(id:)`).
    private(set) var scanAttempt = 0

    static let scanSteps = ["Finder cyklen…", "Genkender delene…", "Finder modellen…"]

    /// 0, 1 eller 2 – skifter undervejs og giver et let haptisk tryk.
    var scanStep: Int { min(Int(scanProgress * 3), 2) }
    var scanStatus: String { scanFound ? "Cykel fundet" : Self.scanSteps[scanStep] }

    func rescan() { scanAttempt += 1 }

    /// Kører scanningen fra 0 til 100 % over ca. 4,5 sekunder.
    func scan() async {
        scanBike = Catalog.bikes.randomElement() ?? scanBike
        scanProgress = 0
        scanFound = false
        let ticks = 150
        do {
            for tick in 1...ticks {
                try await Task.sleep(for: .milliseconds(30))
                scanProgress = Double(tick) / Double(ticks)
            }
            try await Task.sleep(for: .milliseconds(350))
            scanFound = true
        } catch {}  // Annulleret: brugeren gik tilbage.
    }

    // MARK: Stelnummer

    enum Lookup: Equatable {
        case idle, searching, found(Bike), notFound
    }

    /// Altid formateret som "KM 48213 Z".
    var frameNumber = "" {
        didSet {
            let formatted = Self.format(frameNumber)
            if formatted != frameNumber { frameNumber = formatted }
            if lookup != .searching { lookup = .idle }
        }
    }
    private(set) var lookup = Lookup.idle

    static let example = "KM 48213 Z"

    /// Producentkoder → mærke. Opdigtet til demoen.
    static let manufacturers = [
        "KM": "Kildemoes", "AV": "Avenue", "WI": "Winther", "AR": "Raleigh",
        "BA": "Batavus", "GA": "Gazelle", "TR": "Trek", "SP": "Specialized",
        "CY": "Canyon", "CU": "Cube", "LH": "Larry vs Harry", "CH": "Christiania",
    ]

    /// Årgangsbogstaver. I, O og Q bruges ikke, da de ligner tal. A = 2001, Z = 2023, derefter forfra.
    private static let yearLetters = Array("ABCDEFGHJKLMNPRSTUVWXYZ")

    var segments: (code: String, serial: String, letter: String) { Self.segments(frameNumber) }
    var brand: String? { Self.manufacturers[segments.code] }
    var year: Int? { Self.year(for: segments.letter) }
    var canLookup: Bool {
        let s = segments
        return !s.code.isEmpty && s.serial.count >= 4 && year != nil && lookup != .searching
    }

    func findBike() async {
        guard canLookup else { return }
        let brand = brand, year = year
        lookup = .searching
        try? await Task.sleep(for: .seconds(1.2))
        let candidates = Catalog.bikes.filter { $0.brand == brand }
        if let bike = candidates.first(where: { $0.year == year }) ?? candidates.first {
            lookup = .found(bike)
        } else {
            lookup = .notFound
        }
    }

    /// Kode (1–3 bogstaver) + serienummer (op til 8 cifre) + årgangsbogstav.
    static func segments(_ raw: String) -> (code: String, serial: String, letter: String) {
        let chars = raw.uppercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
        let code = chars.prefix(while: \.isLetter).prefix(3)
        let rest = chars.dropFirst(code.count)
        let serial = rest.prefix(while: \.isNumber).prefix(8)
        let letter = serial.isEmpty ? "" : rest.dropFirst(serial.count).prefix(while: \.isLetter).prefix(1)
        return (String(code), String(serial), String(letter))
    }

    static func format(_ raw: String) -> String {
        let s = segments(raw)
        return [s.code, s.serial, s.letter].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// Nyeste årgang, bogstavet kan betyde, som ikke ligger i fremtiden.
    static func year(for letter: String) -> Int? {
        guard let char = letter.first, let index = yearLetters.firstIndex(of: char) else { return nil }
        let current = Calendar.current.component(.year, from: .now)
        var year = 2001 + index
        while year + yearLetters.count <= current { year += yearLetters.count }
        return year
    }
}
