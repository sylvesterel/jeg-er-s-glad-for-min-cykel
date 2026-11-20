import Foundation
import Observation

@Observable
final class GuideViewModel {
    let repair: Repair
    var index = 0
    let startedAt = Date.now
    private(set) var finishedAt: Date?

    init(repair: Repair) { self.repair = repair }

    var steps: [GuideStep] { repair.steps }
    var currentStep: GuideStep? { steps.indices.contains(index) ? steps[index] : nil }
    var isFirst: Bool { index == 0 }
    var isLast: Bool { index >= steps.count - 1 }
    var isFinished: Bool { finishedAt != nil }

    /// Reel tid fra guiden blev åbnet til "Færdig", afrundet til hele minutter (mindst 1).
    var minutesSpent: Int {
        max(1, Int(((finishedAt ?? .now).timeIntervalSince(startedAt) / 60).rounded()))
    }

    func next() {
        if isLast { finishedAt = .now } else { index += 1 }
    }

    func back() {
        index = max(index - 1, 0)
    }
}
