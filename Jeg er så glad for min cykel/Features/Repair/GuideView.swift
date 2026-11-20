import SwiftUI

struct GuideView: View {
    let bike: Bike
    @State private var model: GuideViewModel
    @State private var isPlaying = true
    @State private var replayToken = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(repair: Repair, bike: Bike) {
        self.bike = bike
        _model = State(initialValue: GuideViewModel(repair: repair))
    }

    private var animation: StepAnimation { model.currentStep?.animation ?? .inspect }
    /// Trinnets egen del, ellers reparationens (vedligeholdelse går over flere dele).
    private var part: BikePart { model.currentStep?.part ?? model.repair.part }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Én 3D-visning hele vejen; et nyt trin skifter kun animationen.
                // Til sidst: ingen fremhævning, så cyklen står i fuld farve og drejer roligt.
                Bike3DView(
                    bike: bike,
                    highlight: model.isFinished ? nil : part,
                    focusesHighlight: !model.isFinished,
                    animation: model.isFinished ? nil : animation,
                    isPlaying: isPlaying,
                    replayToken: replayToken
                )
                .containerRelativeFrame(.vertical) { height, _ in height * (model.isFinished ? 0.3 : 0.54) }
                .overlay(alignment: .topTrailing) { if !model.isFinished { playerControls } }
                .overlay(alignment: .bottom) { if !model.isFinished { caption } }

                if model.isFinished {
                    GuideCompletionView(repair: model.repair, minutes: model.minutesSpent) { dismiss() }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    steps
                        .transition(.opacity)
                }
            }
            .background(.background)
            .toolbar {
                if !model.isFinished {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) { dismiss() }
                    }
                }
            }
        }
        .onAppear { isPlaying = !reduceMotion }
        .sensoryFeedback(.selection, trigger: model.index)
        .sensoryFeedback(.success, trigger: model.isFinished)
    }

    private var playerControls: some View {
        GlassEffectContainer {
            HStack(spacing: 8) {
                Button("Se igen", systemImage: "arrow.counterclockwise", action: replay)
                Button(isPlaying ? "Pause" : "Afspil", systemImage: isPlaying ? "pause.fill" : "play.fill") {
                    isPlaying.toggle()
                }
                .labelStyle(.iconOnly)
                .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.glass)
            .font(.subheadline.weight(.semibold))
        }
        .padding(16)
    }

    /// Kort tekst over 3D-scenen, der siger hvad animationen viser.
    private var caption: some View {
        Text(animation.caption(part: part))
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect()
            .padding(.bottom, 12)
            .contentTransition(.opacity)
            .animation(.snappy, value: model.index)
    }

    /// Starter animationen forfra.
    private func replay() {
        replayToken += 1
        isPlaying = true
    }

    private var steps: some View {
        VStack(spacing: 0) {
            SegmentedProgress(count: model.steps.count, index: model.index)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            TabView(selection: $model.index) {
                ForEach(Array(model.steps.enumerated()), id: \.offset) { index, step in
                    StepPage(step: step, number: index + 1, count: model.steps.count)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .safeAreaInset(edge: .bottom) { controls }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button { withAnimation(.snappy) { model.back() } } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 24)
            }
            .buttonStyle(.glass)
            .disabled(model.isFirst)
            .accessibilityLabel("Tilbage")

            Button { withAnimation(.snappy) { model.next() } } label: {
                Text(model.isLast ? "Færdig" : "Næste").frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        }
        .controlSize(.large)
        .font(.headline)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

/// Én tynd streg pr. trin; udførte og aktuelle trin er fyldt.
private struct SegmentedProgress: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(Color.primary.opacity(i <= index ? 0.85 : 0.15))
                    .frame(height: 3)
            }
        }
        .animation(.snappy, value: index)
        .accessibilityElement()
        .accessibilityLabel("Trin \(index + 1) af \(count)")
    }
}

private struct StepPage: View {
    let step: GuideStep
    let number: Int
    let count: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Trin \(number) af \(count)")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Text(step.title)
                    .font(.title.bold())
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.detail)
                    .font(.body)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

                if let warning = step.warning {
                    Callout(text: warning, isWarning: true)
                }
                if let tip = step.tip {
                    Callout(text: tip)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
    }
}

/// Indskudt note. Advarsler skal ses (sikkerhed), tips er venlige og stille.
private struct Callout: View {
    let text: String
    var isWarning = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: isWarning ? "exclamationmark.triangle.fill" : "lightbulb")
                .foregroundStyle(isWarning ? Color.orange : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(isWarning ? "Pas på" : "Godt at vide")
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.subheadline)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            isWarning ? AnyShapeStyle(Color.orange.opacity(0.14)) : AnyShapeStyle(.fill.quaternary),
            in: .rect(cornerRadius: 16)
        )
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }
}

private extension StepAnimation {
    func caption(part: BikePart) -> String {
        switch self {
        case .flipBike: "Sådan vender du cyklen"
        case .removeFrontWheel: "Sådan tager du forhjulet af"
        case .removeRearWheel: "Sådan tager du baghjulet af"
        case .spinWheel: "Drej hjulet langsomt rundt"
        case .deflateTire: "Luk luften ud af dækket"
        case .pumpTire: "Pump luft i dækket"
        case .leverTire: "Lirk dækket af fælgen"
        case .turnPedals: "Drej pedalerne baglæns"
        case .oilChain: "Dryp olie på kæden"
        case .wipeChain: "Tør kæden af med en klud"
        case .removeChain: "Løft kæden af tandhjulene"
        case .squeezeBrake: "Tryk på bremsen"
        case .replaceBrakePads: "Skift bremseklodserne"
        case .adjustCable: "Drej den lille skrue ved grebet"
        case .shiftGears: "Skift gear"
        case .moveSaddle: "Flyt sadlen op eller ned"
        case .tightenBolt: "Stram skruen"
        case .loosenBolt: "Løsn skruen"
        case .alignHandlebar: "Drej styret lige"
        case .switchLight: "Tænd lygten"
        case .unscrewPedal: "Skru pedalen af"
        case .inspect: part.title
        }
    }
}

#Preview("Guide") {
    GuideView(repair: Catalog.repairs[0], bike: Catalog.bikes[0])
}
