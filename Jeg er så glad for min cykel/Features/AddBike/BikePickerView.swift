import SwiftUI

/// Vælg din cykel fra kataloget. Skubbes ind i `AddBikeView`s NavigationStack.
struct BikePickerView: View {
    /// Kaldes med den valgte cykel. nil = sæt den aktive cykel og luk.
    var onSelect: ((Bike) -> Void)? = nil

    @Environment(Garage.self) private var garage
    @Environment(\.dismiss) private var dismiss
    @State private var model = BikePickerViewModel()

    var body: some View {
        List {
            filterChips

            ForEach(model.sections, id: \.brand) { section in
                Section(section.brand) {
                    ForEach(section.bikes) { bike in
                        Button { select(bike) } label: { row(bike) }
                            .tint(.primary)
                    }
                }
            }

            if model.sections.isEmpty {
                ContentUnavailableView.search(text: model.searchText)
                    .listRowBackground(Color.clear)
            }
        }
        .listSectionSpacing(.compact)
        .searchable(text: $model.searchText, prompt: "Mærke eller model")
        .navigationTitle("Vælg cykel")
    }

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip("Alle", isSelected: model.type == nil) { model.type = nil }
                ForEach(BikeType.allCases) { type in
                    chip(type.title, isSelected: model.type == type) { model.type = type }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    @ViewBuilder
    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let label = Text(title).font(.subheadline.weight(.medium))
        if isSelected {
            Button(action: action) { label }.buttonStyle(.glassProminent)
        } else {
            Button(action: action) { label }.buttonStyle(.glass)
        }
    }

    private func row(_ bike: Bike) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(bike.model).font(.body.weight(.medium))
                Text("\(bike.type.title) · \(model.specs(for: bike))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if garage.bike == bike {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 2)
        .contentShape(.rect)
    }

    private func select(_ bike: Bike) {
        if let onSelect {
            onSelect(bike)
        } else {
            garage.bike = bike
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        BikePickerView()
    }
    .environment(Garage())
}
