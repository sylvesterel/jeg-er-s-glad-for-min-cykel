import SwiftUI

/// "Godt gået!"-siden efter sidste trin. Vises under den roligt drejende cykel i GuideView.
struct GuideCompletionView: View {
    let repair: Repair
    let minutes: Int
    let onClose: () -> Void

    @State private var shown = 0
    @State private var checkHidden = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                if repair.savings > 0 { savings }
                if let reminder { Reminder(text: reminder) }
                stats
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) { actions }
        .task { await reveal() }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.green)
                .symbolEffect(.drawOn, isActive: checkHidden)
                .accessibilityHidden(true)
            Text("Godt gået!")
                .font(.largeTitle.bold())
            Text("Du har lavet „\(repair.title)“ helt selv.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private var savings: some View {
        VStack(spacing: 4) {
            Text("Du sparede").sectionLabel()
            Text(shown, format: .dkk)
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.tint)
                .contentTransition(.numericText(value: Double(shown)))
            Text("ved at gøre det selv")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Du sparede \(repair.savings.formatted(.dkk)) ved at gøre det selv"))
    }

    private var stats: some View {
        HStack(spacing: 8) {
            Tile(label: "Tid") { Text("\(minutes) min") }
            Tile(label: "Trin") { Text("\(repair.steps.count)") }
            Tile(label: "Sværhed") { DifficultyBadge(difficulty: repair.difficulty) }
        }
    }

    /// Kun for dele, hvor en fejl kan gøre dig til fare i trafikken.
    private var reminder: String? {
        switch repair.part {
        case .brakes: "Prøv bremserne, før du kører ud i trafikken."
        case .tire: "Tjek lufttrykket, før du kører ud i trafikken."
        default: nil
        }
    }

    private var shareText: String {
        repair.savings > 0
            ? "Jeg har lige lavet „\(repair.title)“ selv og sparet \(repair.savings.formatted(.dkk))."
            : "Jeg har lige lavet „\(repair.title)“ selv."
    }

    private var actions: some View {
        HStack(spacing: 12) {
            ShareLink(item: shareText) {
                Label("Del", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.glass)

            Button(action: onClose) {
                Text("Tilbage til værkstedet").frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        }
        .controlSize(.large)
        .font(.headline)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func reveal() async {
        try? await Task.sleep(for: .milliseconds(250))
        checkHidden = false
        guard !reduceMotion else { shown = repair.savings; return }
        // Tæl op i små hop, så tallet ruller frem i stedet for at springe.
        try? await Task.sleep(for: .milliseconds(300))
        let hops = 20
        for hop in 1...hops {
            try? await Task.sleep(for: .milliseconds(45))
            withAnimation(.snappy(duration: 0.2)) { shown = repair.savings * hop / hops }
        }
    }
}

private struct Tile<Value: View>: View {
    let label: String
    @ViewBuilder let value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).sectionLabel()
            value
                .font(.system(.headline, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.fill.quaternary, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

private struct Reminder: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            (Text("Husk: ").fontWeight(.semibold) + Text(text))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.14), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

private extension Text {
    func sectionLabel() -> some View {
        font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}

#Preview("Godt gået") {
    GuideCompletionView(repair: Catalog.repairs[0], minutes: 12) {}
}
