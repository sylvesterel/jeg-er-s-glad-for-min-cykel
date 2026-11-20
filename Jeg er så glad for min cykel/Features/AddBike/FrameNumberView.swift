import SwiftUI

/// Find cyklen ud fra stelnummeret, fx "KM 48213 Z".
struct FrameNumberView: View {
    @Bindable var model: AddBikeViewModel
    let add: (Bike) -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                explainer
                field

                switch model.lookup {
                case .found(let bike):
                    BikeResultCard(bike: bike, badge: "Præcis match", add: { add(bike) }) {
                        NavigationLink("Ikke den rigtige? Vælg fra listen", value: AddBikeView.Route.list)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                case .notFound:
                    notFound
                case .idle, .searching:
                    findButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .animation(.spring(duration: 0.45, bounce: 0.15), value: model.lookup)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Stelnummer")
        .onAppear { if model.lookup == .idle { isFocused = true } }
        .sensoryFeedback(trigger: model.lookup) { _, lookup in
            switch lookup {
            case .found: .success
            case .notFound: .warning
            default: nil
            }
        }
    }

    private var explainer: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "bicycle")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 52, height: 52)
                .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 14))
            Text("Stelnummeret er et nummer, der er slået ind i selve stellet – typisk på undersiden, lige mellem pedalerne. Vend cyklen på hovedet, og tør snavset af, så du kan læse det.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var field: some View {
        VStack(spacing: 20) {
            TextField(AddBikeViewModel.example, text: $model.frameNumber)
                .font(.system(size: 32, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit(find)

            Divider()

            HStack(alignment: .top) {
                decoded("Mærke", model.segments.code.isEmpty ? nil : model.brand ?? "Ukendt")
                decoded("Løbenummer", model.segments.serial.isEmpty ? nil : model.segments.serial)
                decoded("Årgang", model.year.map(String.init))
            }

            if model.frameNumber.isEmpty {
                Button {
                    model.frameNumber = AddBikeViewModel.example
                } label: {
                    Text("Prøv med \(Text(AddBikeViewModel.example).font(.subheadline.monospaced()))")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 28))
    }

    private func decoded(_ title: String, _ value: String?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Text(value ?? "–")
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(value == nil ? .tertiary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var findButton: some View {
        Button(action: find) {
            HStack(spacing: 8) {
                if model.lookup == .searching {
                    ProgressView()
                    Text("Søger…")
                } else {
                    Text("Find cykel")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .disabled(!model.canLookup)
    }

    private var notFound: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Vi kender ikke koden \(model.segments.code)")
                    .font(.headline)
                Text("Vi kender ikke det mærke endnu. Find din cykel på listen i stedet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            NavigationLink(value: AddBikeView.Route.list) {
                Text("Vælg fra listen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 28))
    }

    private func find() {
        isFocused = false
        Task { await model.findBike() }
    }
}

#Preview {
    NavigationStack {
        FrameNumberView(model: AddBikeViewModel(), add: { _ in })
    }
    .environment(Garage())
}
